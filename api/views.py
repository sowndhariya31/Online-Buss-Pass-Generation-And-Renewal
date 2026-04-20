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
            bus_number = data.get('bus_number', '').strip().upper()
        except:
            main_pass_id = request.POST.get('main_pass_id')
            device_id = request.POST.get('device_id', 'unknown')
            bus_number = request.POST.get('bus_number', '').strip().upper()

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

        BUS_ROUTES = [
            { "no": "78", "start": "KOYAMBEDU", "end": "THIRUVANMIYUR", "stops": ["M.M.D.A.COLONY", "JAFFARKHAN PET", "CIPET", "GUINDY", "ENG.COLLEGE", "ADYAR B.S.", "ADYAR DEPOT"] },
            { "no": "21G", "start": "ISLAND GROUND", "end": "KILAMBAKKAM", "stops": ["SECRETARIAT", "CHEPAUK", "Q.M.C", "MANDAVELI", "ADYAR GATE", "KOTTURPURAM", "GUINDY", "PALLAVARAM", "TAMBARAM", "VANDALUR ZOO"] },
            { "no": "29C", "start": "PERAMBUR", "end": "BESANT NAGAR", "stops": ["SHIVASHANMUGAPURAM", "K.M.C", "STERLING RD", "PONDY BAZAAR", "SAIDAPET", "ENG.COLLEGE", "ADYAR B.S."] },
            { "no": "47A", "start": "VILLIVAKKAM", "end": "THIRUVANMIYUR", "stops": ["KILPAUK GARDEN", "TAYLORS ROAD", "PONDY BAZAAR", "SAIDAPET", "ENG.COLLEGE", "ADYAR B.S."] },
            { "no": "588", "start": "THIRUVANMIYUR", "end": "MAMALLAPURAM", "stops": ["KOTTIVAKKAM", "PALAVAKKAM", "NEELANKARAI", "VETTUVANKENI", "V.G.P", "PANAIYUR", "MUTTUKKADU", "KOVALAM"] },
            { "no": "6D", "start": "TOLLGATE", "end": "THIRUVANMIYUR", "stops": ["PERAMBUR", "EGMORE", "ANNA ROAD", "MANDAVELI", "ADYAR DEPOT"] },
            { "no": "T29", "start": "THIRU.VI.KA.NAGAR", "end": "THIRUVANMIYUR", "stops": ["M.G.R.CENTRAL", "WESLEY H.S", "Y.M.I.A", "MANDAVELI", "ADYAR DEPOT"] },
            { "no": "A1", "start": "M.G.R.CENTRAL", "end": "THIRUVANMIYUR", "stops": ["TAMBARAM WEST", "CHROMEPET", "PALLAVARAM", "V.G.P", "NEELANKARAI", "KOTTIVAKKAM"] },
            { "no": "99", "start": "TAMBARAM WEST", "end": "ADYAR B.S.", "stops": ["GUDUVANCHERY", "VANDALUR ZOO", "TAMBARAM", "CHROMEPET", "KANDANCHAVADI", "THIRUVANMIYUR"] },
            { "no": "91V", "start": "GUDUVANCHERY", "end": "THIRUVANMIYUR", "stops": ["ISLAND GROUND", "CHEPAUK", "Q.M.C", "FORESHORE ESTATE", "ADYAR DEPOT", "KOVALAM"] },
            { "no": "109", "start": "ISLAND GROUND", "end": "KOVALAM", "stops": ["ADYAR B.S.", "THIRUVANMIYUR", "PALAVAKKAM", "NEELANKARAI", "V.G.P", "PANAIYUR", "MUTTUKKADU"] },
            { "no": "109CT", "start": "ADYAR B.S.", "end": "KOVALAM", "stops": ["THIRUVOTRIYUR", "EGMORE", "SECRETARIAT", "CHEPAUK", "FORESHORE ESTATE", "ADYAR DEPOT", "THIRUVANMIYUR"] },
            { "no": "109T", "start": "THIRUVOTRIYUR", "end": "KOVALAM", "stops": ["ISLAND GROUND", "CHEPAUK", "Q.M.C", "FORESHORE ESTATE", "THIRUVANMIYUR", "THIRUPORUR"] },
            { "no": "109X", "start": "ISLAND GROUND", "end": "THIRUPORUR", "stops": ["ADYAR DEPOT", "SRP TOOLS", "THORAPAKKAM", "SHOLINGANALLUR", "PERUMBAKKAM", "KANNAGI NAGAR"] },
            { "no": "102K", "start": "ISLAND GROUND", "end": "KANNAGI NAGAR", "stops": ["CHEPAUK", "Q.M.C", "ADYAR DEPOT", "THORAPAKKAM", "KARAPAKKAM", "SHOLINGANALLUR"] },
            { "no": "102P", "start": "ISLAND GROUND", "end": "PERUMPAKKAM", "stops": ["CHEPAUK", "Q.M.C", "ADYAR DEPOT", "THORAPAKKAM", "KARAPAKKAM", "SHOLINGANALLUR"] }
        ]

        if main_pass.pass_type == 'STUDENT':
            # Route Validation
            if bus_number:
                bus_route = next((r for r in BUS_ROUTES if r['no'].upper() == bus_number), None)
                if not bus_route:
                    return JsonResponse({"status": "error", "message": f"Bus {bus_number} not found in predefined valid routes!"}, status=403)
                
                all_stops = [bus_route['start']] + bus_route['stops'] + [bus_route['end']]
                # Ensure all are uppercase for matching
                all_stops = [s.upper().strip() for s in all_stops]
                
                route_from = main_pass.user.route_from.strip().upper() if main_pass.user.route_from else ""
                route_to = main_pass.user.route_to.strip().upper() if main_pass.user.route_to else ""
                
                if route_from not in all_stops or route_to not in all_stops:
                    return JsonResponse({
                        "status": "error", 
                        "message": f"Invalid Route! Bus {bus_number} does not serve your path ({route_from} - {route_to})."
                    }, status=403)

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
