import os
import sys
import django

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from passes.models import MainPass, MonthlyRenewal

print("--- MAIN PASSES ---")
for p in MainPass.objects.all():
    print(f"ID: {p.pk}, PassID: {p.main_pass_id}, Status: {p.status}, PaymentStatus: {p.payment_status}, RazorpayOrderID: {p.razorpay_order_id}")

print("\n--- MONTHLY RENEWALS ---")
for r in MonthlyRenewal.objects.all():
    print(f"ID: {r.pk}, PassID: {r.main_pass.main_pass_id}, Month: {r.month}, Status: {r.payment_status}, RazorpayOrderID: {r.razorpay_order_id}")
