from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import MainPass, MonthlyRenewal, UsageLog
from django.http import HttpResponse
from django.utils import timezone
import datetime
import razorpay
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt

from .forms import ApplyPassForm, PassDetailForm

# Initialize Razorpay Client
razorpay_client = razorpay.Client(
    auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
)

@login_required
def apply_pass(request):
    # Strict one-time application check
    existing_pass = MainPass.objects.filter(user=request.user).first()
    if existing_pass:
        return redirect('dashboard')

    if request.method == 'POST':
        pass_form = ApplyPassForm(request.POST)
        detail_form = PassDetailForm(request.POST, request.FILES, instance=request.user)
        
        if pass_form.is_valid() and detail_form.is_valid():
            # Update User Profile
            user = detail_form.save()
            
            # Default to STUDENT for everyone as requested
            pass_type = 'STUDENT'
            user.role = pass_type
            user.save()
            
            # Create Main Pass
            expiry_date = timezone.now().date() + datetime.timedelta(days=365)
            
            MainPass.objects.create(
                user=request.user,
                pass_type=pass_type,
                expiry_date=expiry_date,
                status='PENDING'
            )
            return redirect('dashboard')
    else:
        pass_form = ApplyPassForm()
        detail_form = PassDetailForm(instance=request.user)
        
    return render(request, 'passes/apply.html', {
        'pass_form': pass_form,
        'detail_form': detail_form
    })

def renew_pass(request, pk):
    main_pass = get_object_or_404(MainPass, pk=pk)
    
    if request.method == 'POST':
        month_str = request.POST.get('month')
        if month_str:
            renewal, created = MonthlyRenewal.objects.get_or_create(
                main_pass=main_pass,
                month=month_str,
                defaults={
                    'valid_from': timezone.now().date(),
                    'valid_to': timezone.now().date() + datetime.timedelta(days=30),
                    'payment_status': 'PENDING'
                }
            )
            return redirect('pay_renewal', pk=renewal.pk)
            
    months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']
    current_month_idx = timezone.now().month - 1
    available_months = [months[(current_month_idx + i) % 12] for i in range(3)]
    
    return render(request, 'passes/renew.html', {'main_pass': main_pass, 'available_months': available_months})

@login_required
def approve_pass(request, pk):
    if not (request.user.role == 'ADMIN' or request.user.is_superuser or request.user.is_staff):
        return redirect('dashboard')
        
    main_pass = get_object_or_404(MainPass, pk=pk)
    if main_pass.status == 'PENDING':
        action = request.POST.get('action')
        if action == 'approve':
            main_pass.status = 'ACTIVE'
            # save() will auto-generate the main_pass_id if it's missing
            main_pass.save()
        elif action == 'reject':
            main_pass.status = 'BLOCKED'
            main_pass.save()
        
    return redirect('dashboard')

@login_required
def download_pass(request, pk):
    from .utils import generate_qr_base64
    from django.utils import timezone
    main_pass = get_object_or_404(MainPass, pk=pk, user=request.user)
    if not main_pass.is_currently_valid:
        return redirect('dashboard')
    
    active_id = main_pass.main_pass_id
    today = timezone.now().date()
    current_month = today.strftime('%b').upper()
    active_renewal = main_pass.renewals.filter(month=current_month, payment_status='PAID').first()
    
    if active_renewal and active_renewal.renewal_id:
        active_id = active_renewal.renewal_id
        
    qr_data = f"{active_id}"
    qr_code = generate_qr_base64(qr_data)
    
    return render(request, 'passes/download.html', {
        'main_pass': main_pass,
        'active_id': active_id,
        'qr_code': qr_code
    })

def pay_pass(request, pk):
    main_pass = get_object_or_404(MainPass, pk=pk)
    
    # Only allow payment if admin has approved (status is ACTIVE)
    if main_pass.status != 'ACTIVE':
        return render(request, 'passes/payment_status.html', {
            'status': 'PENDING_APPROVAL',
            'message': 'Your pass is currently pending admin approval. Please wait for the admin to approve before paying.'
        })
    
    # Skip if already paid
    if main_pass.payment_status == 'PAID':
        return render(request, 'passes/payment_status.html', {
            'status': 'PAID',
            'message': 'Payment already completed successfully! You can close this tab and return to the City Pass app.'
        })
        
    amount_rupees = 280 if main_pass.pass_type == 'STUDENT' else 1000
    
    amount_rupees = 280 if main_pass.pass_type == 'STUDENT' else 1000
    currency = 'INR'
    amount_paise = amount_rupees * 100

    # Create Razorpay Order
    razorpay_order = razorpay_client.order.create({
        'amount': amount_paise,
        'currency': currency,
        'payment_capture': '1'
    })
    razorpay_order_id = razorpay_order['id']
    
    # Save the order ID to the pass record for later verification
    main_pass.razorpay_order_id = razorpay_order_id
    main_pass.save()

    context = {
        'main_pass': main_pass,
        'amount': amount_rupees,
        'razorpay_order_id': razorpay_order_id,
        'razorpay_merchant_key': settings.RAZORPAY_KEY_ID,
        'razorpay_amount': amount_paise,
        'currency': currency,
        'user': main_pass.user,
        'callback_url': request.build_absolute_uri('/passes/paymenthandler/')
    }
    
    return render(request, 'passes/pay.html', context=context)


def pay_renewal(request, pk):
    renewal = get_object_or_404(MonthlyRenewal, pk=pk)
    main_pass = renewal.main_pass
    
    # Skip if already paid
    if renewal.payment_status == 'PAID':
        return render(request, 'passes/payment_status.html', {
            'status': 'PAID',
            'message': 'Payment already completed successfully! You can close this tab and return to the City Pass app.'
        })
    
    amount_rupees = 280 if main_pass.pass_type == 'STUDENT' else 1000
    
    amount_rupees = 280 if main_pass.pass_type == 'STUDENT' else 1000
    currency = 'INR'
    amount_paise = amount_rupees * 100

    # Create Razorpay Order
    razorpay_order = razorpay_client.order.create({
        'amount': amount_paise,
        'currency': currency,
        'payment_capture': '1'
    })
    razorpay_order_id = razorpay_order['id']
    
    # Save the order ID to the renewal record for later verification
    renewal.razorpay_order_id = razorpay_order_id
    renewal.save()

    context = {
        'renewal': renewal,
        'main_pass': main_pass,
        'amount': amount_rupees,
        'razorpay_order_id': razorpay_order_id,
        'razorpay_merchant_key': settings.RAZORPAY_KEY_ID,
        'razorpay_amount': amount_paise,
        'currency': currency,
        'user': main_pass.user,
        'callback_url': request.build_absolute_uri('/passes/paymenthandler/')
    }
    
    return render(request, 'passes/pay_renewal.html', context=context)


@csrf_exempt
def paymenthandler(request):
    if request.method == "POST":
        try:
            # get the required parameters from post request.
            payment_id = request.POST.get('razorpay_payment_id', '')
            razorpay_order_id = request.POST.get('razorpay_order_id', '')
            signature = request.POST.get('razorpay_signature', '')
            
            params_dict = {
                'razorpay_order_id': razorpay_order_id,
                'razorpay_payment_id': payment_id,
                'razorpay_signature': signature
            }

            # verify the payment signature.
            try:
                razorpay_client.utility.verify_payment_signature(params_dict)
            except Exception as e:
                # signature verification failed
                print(f"Signature Verification Failed: {e}")
                return render(request, 'passes/payment_failed.html')

            # Verification Successful - find the record by order_id
            from .models import MainPass, MonthlyRenewal
            
            # 1. Look for a Main Pass with this order ID
            main_pass = MainPass.objects.filter(razorpay_order_id=razorpay_order_id).first()
            if main_pass:
                if main_pass.payment_status != 'PAID':
                    main_pass.payment_status = 'PAID'
                    main_pass.save()
                    main_pass.generate_pass_id()
                    
                    # Also mark current month's renewal if it exists
                    today = timezone.now().date()
                    current_month = today.strftime('%b').upper()
                    renewal = main_pass.renewals.filter(month=current_month, payment_status='PENDING').first()
                    if renewal:
                        renewal.payment_status = 'PAID'
                        renewal.save()
                        renewal.generate_renewal_id()
                
                return render(request, 'passes/payment_success.html', {'payment_id': payment_id})

            # 2. Look for a Monthly Renewal with this order ID
            renewal = MonthlyRenewal.objects.filter(razorpay_order_id=razorpay_order_id).first()
            if renewal:
                if renewal.payment_status != 'PAID':
                    renewal.payment_status = 'PAID'
                    renewal.save()
                    renewal.generate_renewal_id()
                    
                    # Update main pass validity
                    mp = renewal.main_pass
                    if not mp.current_valid_to or renewal.valid_to > mp.current_valid_to:
                        mp.current_valid_to = renewal.valid_to
                        mp.save()
                
                return render(request, 'passes/payment_success.html', {'payment_id': payment_id})

            return render(request, 'passes/payment_failed.html')

            return render(request, 'passes/payment_failed.html')

        except Exception as e:
            # if we are not able to find the pass/renewal or some other error
            return render(request, 'passes/payment_failed.html')
    else:
        # if post request is not come
        return redirect('dashboard')


@login_required
def scanner_view(request):
    # Admin/Staff/Conductor can access the scanner
    if not (request.user.role in ['ADMIN', 'CONDUCTOR'] or request.user.is_superuser or request.user.is_staff):
        return redirect('dashboard')
        
    if request.method == 'POST':
        action = request.POST.get('action')
        if action == 'login':
            bus_number = request.POST.get('bus_number', '').strip().upper()
            password = request.POST.get('password', '')
            if bus_number and password.lower() == 'conductor2722':
                request.session['logged_in_bus_number'] = bus_number
                return redirect('scanner')
            else:
                return render(request, 'passes/scanner_login.html', {'error': 'Invalid Bus Number or Password'})
        elif action == 'logout':
            if 'logged_in_bus_number' in request.session:
                del request.session['logged_in_bus_number']
            return redirect('scanner')
            
    if 'logged_in_bus_number' not in request.session:
        return render(request, 'passes/scanner_login.html')
        
    return render(request, 'passes/scanner.html', {'bus_number': request.session['logged_in_bus_number']})

@login_required
def download_id_card(request, pk):
    main_pass = get_object_or_404(MainPass, pk=pk, user=request.user)
    
    # Only allow ID card download if pass ID has been generated (after payment)
    if not main_pass.main_pass_id:
        return redirect('dashboard')
    
    # Determine which ID to encode in the QR code (Monthly Renewal > Main)
    active_id = main_pass.main_pass_id
    today = timezone.now().date()
    current_month = today.strftime('%b').upper()
    active_renewal = main_pass.renewals.filter(month=current_month, payment_status='PAID').first()
    
    if active_renewal and active_renewal.renewal_id:
        active_id = active_renewal.renewal_id
        
    from .utils import generate_qr_base64
    qr_data = f"{active_id}"
    qr_code = generate_qr_base64(qr_data)
    
    return render(request, 'passes/id_card.html', {
        'main_pass': main_pass,
        'active_id': active_id,
        'qr_code': qr_code
    })
def renew_search_view(request):
    if request.method == 'POST':
        pass_id = request.POST.get('pass_id')
        if not pass_id:
            return render(request, 'passes/renew_search.html', {'error': 'Please enter a Pass ID'})
            
        pass_id = pass_id.strip()
        
        main_pass = None
        if pass_id.startswith('REN'):
            renewal = MonthlyRenewal.objects.filter(renewal_id=pass_id).first()
            if renewal:
                main_pass = renewal.main_pass
        else:
            main_pass = MainPass.objects.filter(main_pass_id=pass_id).first()
            
        if main_pass:
            return redirect('renew_pass', pk=main_pass.pk)
        else:
            return render(request, 'passes/renew_search.html', {'error': 'Invalid Pass ID'})
    return render(request, 'passes/renew_search.html')

@login_required
def edit_pass_view(request, pk):
    if not (request.user.role == 'ADMIN' or request.user.is_superuser or request.user.is_staff):
        return redirect('dashboard')
    
    main_pass = get_object_or_404(MainPass, pk=pk)
    if request.method == 'POST':
        main_pass.status = request.POST.get('status', main_pass.status)
        main_pass.expiry_date = request.POST.get('expiry_date', main_pass.expiry_date)
        main_pass.save()
        from django.contrib import messages
        messages.success(request, f"Pass {main_pass.main_pass_id} updated.")
        return redirect('dashboard')
    
    return render(request, 'passes/edit_pass.html', {'p': main_pass})

@login_required
def delete_pass_view(request, pk):
    if not (request.user.role == 'ADMIN' or request.user.is_superuser or request.user.is_staff):
        return redirect('dashboard')
    
    main_pass = get_object_or_404(MainPass, pk=pk)
    pass_id = main_pass.main_pass_id or "Pending Pass"
    main_pass.delete()
    from django.contrib import messages
    messages.warning(request, f"Pass {pass_id} deleted.")
    return redirect('dashboard')

