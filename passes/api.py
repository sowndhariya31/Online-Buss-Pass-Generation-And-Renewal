from rest_framework import generics, permissions
from rest_framework.response import Response
from .models import MainPass, MonthlyRenewal, UsageLog
from .serializers import MainPassSerializer, MonthlyRenewalSerializer, ApplyPassSerializer

class MainPassListAPIView(generics.ListAPIView):
    serializer_class = MainPassSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        return MainPass.objects.filter(user=self.request.user).order_by('-issue_date')

class MonthlyRenewalListAPIView(generics.ListAPIView):
    serializer_class = MonthlyRenewalSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        main_pass_id = self.kwargs['pass_id']
        return MonthlyRenewal.objects.filter(main_pass__pass_id=main_pass_id, main_pass__user=self.request.user).order_by('-created_at')

class ApplyPassAPIView(generics.CreateAPIView):
    serializer_class = ApplyPassSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def perform_create(self, serializer):
        from django.utils import timezone
        import datetime
        
        user = self.request.user
        # Update user profile with the new details sent in the request
        user.college = self.request.data.get('college_name', user.college)
        user.address = self.request.data.get('address', user.address)
        user.route_from = self.request.data.get('route_from', user.route_from)
        user.route_to = self.request.data.get('route_to', user.route_to)
        
        if 'photo' in self.request.FILES:
            user.photo = self.request.FILES['photo']
        if 'id_proof' in self.request.FILES:
            user.id_proof = self.request.FILES['id_proof']
        user.save()

        # Default expiry to 1 year from now
        expiry = timezone.now().date() + datetime.timedelta(days=365)
        # Default pass_type if not provided
        pass_type = self.request.data.get('pass_type', 'STUDENT')
        serializer.save(user=user, expiry_date=expiry, pass_type=pass_type)

class AdminPassListAPIView(generics.ListAPIView):
    serializer_class = MainPassSerializer
    permission_classes = (permissions.IsAdminUser,)
    queryset = MainPass.objects.all().order_by('-issue_date')

class AdminPassActionAPIView(generics.UpdateAPIView):
    serializer_class = MainPassSerializer
    permission_classes = (permissions.IsAdminUser,)
    queryset = MainPass.objects.all()

    def patch(self, request, *args, **kwargs):
        instance = self.get_object()
        status = request.data.get('status')
        if status in ['APPROVED', 'REJECTED']:
            if status == 'APPROVED':
                instance.status = 'ACTIVE'
            else:
                instance.status = 'BLOCKED'
            instance.save()
            return Response(MainPassSerializer(instance, context={'request': request}).data)
        return Response({'error': 'Invalid status'}, status=400)

    def delete(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response({'message': 'Pass deleted successfully'}, status=200)

class ConfirmPaymentAPIView(generics.UpdateAPIView):
    serializer_class = MainPassSerializer
    permission_classes = (permissions.IsAuthenticated,)
    queryset = MainPass.objects.all()

    def patch(self, request, *args, **kwargs):
        from django.utils import timezone
        import datetime
        
        instance = self.get_object()
        today = timezone.now().date()
        current_month = today.strftime('%b').upper()
        selected_month = (request.data.get('month') or current_month).upper()
        
        if instance.payment_status != 'PAID':
            # 1. Initial Payment
            instance.payment_status = 'PAID'
            instance.generate_pass_id() # Generate permanent pass ID only ONCE
            instance.save()
            
            # Create first monthly renewal automatically
            renewal, created = MonthlyRenewal.objects.get_or_create(
                main_pass=instance,
                month=selected_month,
                defaults={
                    'valid_from': today,
                    'valid_to': today + datetime.timedelta(days=30),
                    'payment_status': 'PAID'
                }
            )
            if not created:
                renewal.payment_status = 'PAID'
            renewal.generate_renewal_id()
            renewal.save()
            
            instance.current_valid_to = renewal.valid_to
            instance.save()
        else:
            # 2. Monthly Renewal Payment (Subsequent payments)
            # Permanent ID is already generated and shown, do not overwrite it!
            # Instead, create/pay the monthly renewal
            renewal, created = MonthlyRenewal.objects.get_or_create(
                main_pass=instance,
                month=selected_month,
                defaults={
                    'valid_from': today,
                    'valid_to': today + datetime.timedelta(days=30),
                    'payment_status': 'PAID'
                }
            )
            if not created:
                renewal.payment_status = 'PAID'
            renewal.generate_renewal_id() # Generates a different renewal ID every month
            renewal.save()
            
            instance.current_valid_to = renewal.valid_to
            instance.save()
            
        return Response(MainPassSerializer(instance, context={'request': request}).data)

class VerifyPassAPIView(generics.RetrieveAPIView):
    serializer_class = MainPassSerializer
    permission_classes = (permissions.IsAuthenticated,)
    queryset = MainPass.objects.all()

    def get_object(self):
        from django.shortcuts import get_object_or_404
        pass_id = self.kwargs.get('main_pass_id')
        if pass_id and pass_id.startswith('REN'):
            renewal = get_object_or_404(MonthlyRenewal, renewal_id=pass_id)
            return renewal.main_pass
        return get_object_or_404(MainPass, main_pass_id=pass_id)

    # Route data matching find_route.html
    BUS_ROUTES = {
        "78": ["KOYAMBEDU", "THIRUVANMIYUR"],
        "21G": ["ISLAND GROUND", "KILAMBAKKAM"],
        "29C": ["PERAMBUR", "BESANT NAGAR"],
        "47A": ["VILLIVAKKAM", "THIRUVANMIYUR"],
        "588": ["THIRUVANMIYUR", "MAMALLAPURAM"],
        "6D": ["TOLLGATE", "THIRUVANMIYUR"],
        "T29": ["THIRU.VI.KA.NAGAR", "THIRUVANMIYUR"],
        "A1": ["M.G.R.CENTRAL", "THIRUVANMIYUR"],
        "99": ["TAMBARAM WEST", "ADYAR B.S."],
        "91V": ["GUDUVANCHERY", "THIRUVANMIYUR"],
        "109": ["ISLAND GROUND", "KOVALAM"],
        "109CT": ["ADYAR B.S.", "KOVALAM"],
        "109T": ["THIRUVOTRIYUR", "KOVALAM"],
        "109X": ["ISLAND GROUND", "THIRUPORUR"],
        "102K": ["ISLAND GROUND", "KANNAGI NAGAR"],
        "102P": ["ISLAND GROUND", "PERUMPAKKAM"]
    }

    def get(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Check if the pass is currently valid (has active renewal)
        if not instance.is_currently_valid:
            return Response({
                'error': 'Pass is not currently valid. Please check monthly renewal status.',
                'pass_id': instance.main_pass_id
            }, status=400)

        # Count scans for today
        from django.utils import timezone
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        today_scans = instance.usage_logs.filter(scan_time__gte=today_start).count()

        # Enforce Student pass limit of 2 daily activations
        if instance.pass_type == 'STUDENT':
            if today_scans >= 2:
                return Response({
                    'error': 'Limit Exceeded! Student passes are only valid for 2 daily trips.',
                    'pass_type': 'STUDENT'
                }, status=400)

        conductor = request.user
        
        # Student Pass Route Verification
        if instance.pass_type == 'STUDENT' and conductor.role == 'CONDUCTOR':
            student = instance.user
            bus_no = (conductor.bus_number or "").strip().upper()
            student_from = (student.route_from or "").strip().upper()
            student_to = (student.route_to or "").strip().upper()
            
            allowed_route = self.BUS_ROUTES.get(bus_no)
            if allowed_route:
                # Check if the student's route (from/to) matches this bus's route (start/end)
                if student_from not in allowed_route or student_to not in allowed_route:
                    return Response({
                        'error': f'Route Mismatch! Bus {bus_no} does not serve {student_from} ⇌ {student_to}.',
                        'pass_type': 'STUDENT'
                    }, status=400)
            else:
                return Response({
                    'error': f'Access Denied! Conductor bus number "{bus_no}" is not registered on a valid passenger route.',
                    'pass_type': 'STUDENT'
                }, status=400)

        # Record usage log
        UsageLog.objects.create(
            main_pass=instance,
            trip_number=today_scans + 1,
            device_id=conductor.bus_number
        )
        instance.daily_trip_count = today_scans + 1
        instance.save()
        return super().get(request, *args, **kwargs)

class UsageLogListAPIView(generics.ListAPIView):
    serializer_class = MainPassSerializer # Simplified for now
    permission_classes = (permissions.IsAdminUser,)
    queryset = UsageLog.objects.all().order_by('-scan_time')

    def get(self, request, *args, **kwargs):
        logs = UsageLog.objects.all().order_by('-scan_time')[:50]
        data = [{
            'id': log.id,
            'pass_id': log.main_pass.main_pass_id,
            'user': log.main_pass.user.email,
            'time': log.scan_time,
            'trip': log.trip_number
        } for log in logs]
        return Response(data)

from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework import status
from django.conf import settings
import razorpay

razorpay_client = razorpay.Client(
    auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
)

class InitiateRazorpayAPIView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, pk):
        from .models import MainPass, MonthlyRenewal
        main_pass = get_object_or_404(MainPass, pk=pk, user=request.user)
        
        is_monthly = request.data.get('is_monthly', False)
        selected_month = (request.data.get('month') or '').upper()
        
        amount_rupees = 280 if main_pass.pass_type == 'STUDENT' else 1000
        amount_paise = amount_rupees * 100
        currency = 'INR'
        
        # Create Razorpay Order
        try:
            razorpay_order = razorpay_client.order.create({
                'amount': amount_paise,
                'currency': currency,
                'payment_capture': '1'
            })
            razorpay_order_id = razorpay_order['id']
        except Exception as e:
            return Response({
                'error': f'Razorpay Order Creation Failed: {str(e)}. Please check if RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET are configured properly in your server environment.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if is_monthly and selected_month:
            # Monthly Renewal payment order
            from django.utils import timezone
            import datetime
            today = timezone.now().date()
            
            renewal, created = MonthlyRenewal.objects.get_or_create(
                main_pass=main_pass,
                month=selected_month,
                defaults={
                    'valid_from': today,
                    'valid_to': today + datetime.timedelta(days=30),
                    'payment_status': 'PENDING'
                }
            )
            renewal.razorpay_order_id = razorpay_order_id
            renewal.save()
            payment_url = request.build_absolute_uri(f'/passes/pay-renewal/{renewal.pk}/')
        else:
            # Initial Pass payment order
            main_pass.razorpay_order_id = razorpay_order_id
            main_pass.save()
            payment_url = request.build_absolute_uri(f'/passes/pay/{main_pass.pk}/')
            
        return Response({
            'key': settings.RAZORPAY_KEY_ID,
            'amount': str(amount_paise),
            'order_id': razorpay_order_id,
            'currency': currency,
            'name': 'CITY PASS',
            'email': request.user.email,
            'contact': request.user.phone if hasattr(request.user, 'phone') else '',
            'payment_url': payment_url,
        })

class VerifyRazorpayPaymentAPIView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        payment_id = request.data.get('razorpay_payment_id', '')
        razorpay_order_id = request.data.get('razorpay_order_id', '')
        signature = request.data.get('razorpay_signature', '')
        
        params_dict = {
            'razorpay_order_id': razorpay_order_id,
            'razorpay_payment_id': payment_id,
            'razorpay_signature': signature
        }
        
        # Verify the signature
        try:
            razorpay_client.utility.verify_payment_signature(params_dict)
        except Exception as e:
            return Response({'error': f'Signature verification failed: {e}'}, status=status.HTTP_400_BAD_REQUEST)
            
        # Update record status
        from django.utils import timezone
        import datetime
        from .models import MainPass, MonthlyRenewal
        
        main_pass = MainPass.objects.filter(razorpay_order_id=razorpay_order_id).first()
        if main_pass:
            if main_pass.payment_status != 'PAID':
                main_pass.payment_status = 'PAID'
                main_pass.save()
                main_pass.generate_pass_id()
                
                # Auto-create/mark first monthly renewal
                today = timezone.now().date()
                current_month = today.strftime('%b').upper()
                renewal, created = MonthlyRenewal.objects.get_or_create(
                    main_pass=main_pass,
                    month=current_month,
                    defaults={
                        'valid_from': today,
                        'valid_to': today + datetime.timedelta(days=30),
                        'payment_status': 'PAID'
                    }
                )
                if not created:
                    renewal.payment_status = 'PAID'
                renewal.generate_renewal_id()
                renewal.save()
                
                main_pass.current_valid_to = renewal.valid_to
                main_pass.save()
                
            return Response(MainPassSerializer(main_pass, context={'request': request}).data)
            
        renewal = MonthlyRenewal.objects.filter(razorpay_order_id=razorpay_order_id).first()
        if renewal:
            if renewal.payment_status != 'PAID':
                renewal.payment_status = 'PAID'
                renewal.save()
                renewal.generate_renewal_id()
                
                main_pass = renewal.main_pass
                main_pass.current_valid_to = renewal.valid_to
                main_pass.save()
                
            return Response(MainPassSerializer(main_pass, context={'request': request}).data)
            
        return Response({'error': 'Order ID not found'}, status=status.HTTP_404_NOT_FOUND)
