import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from django.contrib.auth import get_user_model
from passes.models import MainPass
from django.test import Client

User = get_user_model()
c = Client(HTTP_HOST='localhost')

# Ensure user exists (from previous run or create new)
student = User.objects.filter(username='student_pay').first()
if not student:
    student = User.objects.create_user(username='student_pay', password='password123', role='STUDENT')
admin = User.objects.filter(username='admin_pay').first()
if not admin:
    admin = User.objects.create_superuser(username='admin_pay', password='password123', email='admin@test.com', role='ADMIN')

MainPass.objects.all().delete()

# Test Apply Pass via Client
c.login(username='student_pay', password='password123')
c.post('/passes/apply/')
pending_pass = MainPass.objects.get(user=student)
print(f'Student applied. Status: {pending_pass.status}, Payment: {pending_pass.payment_status}')

# Test Approve Pass via Admin
c.login(username='admin_pay', password='password123')
c.post(f'/passes/approve/{pending_pass.pk}/')
approved_pass = MainPass.objects.get(user=student)
print(f'Admin approved. Status: {approved_pass.status}, Payment: {approved_pass.payment_status}')

# Try download (should exist but UI logic blocks it, let's verify view handles it properly by returning ok)
c.login(username='student_pay', password='password123')

# Trigger payment
r_pay = c.post(f'/passes/pay/{approved_pass.pk}/')
paid_pass = MainPass.objects.get(user=student)
print(f'Student paid. ID: {paid_pass.main_pass_id}, Status: {paid_pass.status}, Payment: {paid_pass.payment_status}')

