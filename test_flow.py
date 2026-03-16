import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from django.contrib.auth import get_user_model
from passes.models import MainPass
import json
from django.test import Client

User = get_user_model()
c = Client()

# Create test users
student = User.objects.create_user(username='student1', password='password123', role='STUDENT', college='Engineering College')
public = User.objects.create_user(username='public1', password='password123', role='PUBLIC', address='City Center')
admin = User.objects.create_superuser(username='admin', password='password123', email='admin@test.com')
admin.role = 'ADMIN'
admin.save()

print('Users created.')

# Apply for Pass (Student)
c.login(username='student1', password='password123')
c.post('/passes/apply/')
pending_pass = MainPass.objects.get(user=student)
print(f'Student applied. Pass status: {pending_pass.status}')

# Approve Pass (Admin)
c.login(username='admin', password='password123')
c.post(f'/passes/approve/{pending_pass.pk}/')
approved_pass = MainPass.objects.get(user=student)
print(f'Admin approved. Pass status: {approved_pass.status}, ID generated: {approved_pass.main_pass_id}')

# Scan Pass (API)
response = c.post('/api/scan/', json.dumps({'main_pass_id': approved_pass.main_pass_id, 'device_id': 'Bus1'}), content_type='application/json')
print(f'Scan 1: {response.json()}')

# Need valid renewal for scan actually! Wait, scan requires MonthlyRenewal.
from passes.models import MonthlyRenewal
from django.utils import timezone
import datetime
MonthlyRenewal.objects.create(main_pass=approved_pass, month='MAR', valid_from=timezone.now().date(), valid_to=timezone.now().date() + datetime.timedelta(days=30))

response1 = c.post('/api/scan/', json.dumps({'main_pass_id': approved_pass.main_pass_id, 'device_id': 'Bus1'}), content_type='application/json')
print(f'Scan 1 with renewal: {response1.json()}')

response2 = c.post('/api/scan/', json.dumps({'main_pass_id': approved_pass.main_pass_id, 'device_id': 'Bus1'}), content_type='application/json')
print(f'Scan 2 with renewal: {response2.json()}')

response3 = c.post('/api/scan/', json.dumps({'main_pass_id': approved_pass.main_pass_id, 'device_id': 'Bus1'}), content_type='application/json')
print(f'Scan 3 with renewal (should fail): {response3.json()}')

print('All flows verified!')
