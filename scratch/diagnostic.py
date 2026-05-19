import os
import sys
import django

# Set up Django environment
sys.path.append('c:\\htmlproject\\buspass')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from passes.models import MainPass

try:
    passes = MainPass.objects.all()
    print(f"Total passes: {passes.count()}")
    for idx, p in enumerate(passes):
        print(f"[{idx}] ID: {p.pk}, main_pass_id: {p.main_pass_id}, payment_status: {p.payment_status}, razorpay_order_id: {p.razorpay_order_id!r}, status: {p.status}")
except Exception as e:
    import traceback
    print("Error querying database:")
    traceback.print_exc()
