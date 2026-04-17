from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from passes.models import MainPass, MonthlyRenewal, UsageLog
from django.utils import timezone
import json

@csrf_exempt
def scan_pass(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            main_pass_id = data.get('main_pass_id')
            device_id = data.get('device_id', 'unknown')
        except:
            main_pass_id = request.POST.get('main_pass_id')
            device_id = request.POST.get('device_id', 'unknown')

        if not main_pass_id:
            return JsonResponse({"status": "error", "message": "Missing Pass ID"}, status=400)

        # Allow scanning either a Monthly Renewal ID (REN...) or a Main Pass ID (MTC.../PUB...)
        main_pass = None
        is_renewal_scan = False
        
        if main_pass_id.startswith('REN'):
            try:
                renewal = MonthlyRenewal.objects.get(renewal_id=main_pass_id)
                main_pass = renewal.main_pass
                is_renewal_scan = True
                
                if renewal.payment_status != 'PAID':
                    return JsonResponse({"status": "error", "message": "Renewal Payment Pending!"}, status=403)
                    
                today = timezone.now().date()
                if today < renewal.valid_from or today > renewal.valid_to:
                    return JsonResponse({"status": "error", "message": "Renewal is expired or not yet valid!"}, status=403)
                    
            except MonthlyRenewal.DoesNotExist:
                return JsonResponse({"status": "error", "message": "Invalid Renewal ID"}, status=404)
        else:
            return JsonResponse({"status": "error", "message": "Please scan the Active Renewal ID (REN...) instead of the Permanent ID."}, status=403)

        if main_pass.status != 'ACTIVE':
            return JsonResponse({"status": "error", "message": f"Pass is {main_pass.status}"}, status=403)

        today = timezone.now().date()
        if main_pass.expiry_date < today:
            return JsonResponse({"status": "error", "message": "Pass Expired Yearly"}, status=403)

        # Usage Logic
        if today != main_pass.last_used_date:
            main_pass.daily_trip_count = 0
            main_pass.last_used_date = today

        if main_pass.pass_type == 'STUDENT':
            if main_pass.daily_trip_count >= 2:
                return JsonResponse({"status": "error", "message": "Daily Limit Reached (Max 2 trips/day)"}, status=403)
            
            main_pass.daily_trip_count += 1
            main_pass.save()
            
            UsageLog.objects.create(
                main_pass=main_pass, 
                trip_number=main_pass.daily_trip_count, 
                device_id=device_id
            )
            return JsonResponse({
                "status": "success", 
                "message": f"Success! Trips today: {main_pass.daily_trip_count}/2", 
                "trip_number": main_pass.daily_trip_count,
                "remaining_trips": 2 - main_pass.daily_trip_count,
                "user": main_pass.user.get_full_name() or main_pass.user.username,
                "type": "STUDENT",
                "scanned_id": main_pass_id
            })
        else:
            main_pass.daily_trip_count += 1
            main_pass.save()
            
            UsageLog.objects.create(
                main_pass=main_pass, 
                trip_number=main_pass.daily_trip_count, 
                device_id=device_id
            )
            return JsonResponse({
                "status": "success", 
                "message": "Success! Unlimited Access granted.", 
                "trip_number": main_pass.daily_trip_count,
                "user": main_pass.user.get_full_name() or main_pass.user.username,
                "type": "PUBLIC",
                "scanned_id": main_pass_id
            })

    return JsonResponse({"status": "error", "message": "Method not allowed"}, status=405)
