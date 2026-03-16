import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from django.contrib.auth import get_user_model
from passes.models import MainPass, MonthlyRenewal, UsageLog
import json
from django.test import Client

User = get_user_model()
c = Client(HTTP_HOST='localhost')

# Ensure user exists (from previous run)
student = User.objects.filter(username='student1').first()
if not student:
    student = User.objects.create_user(username='student1', password='password123', role='STUDENT')
admin = User.objects.filter(username='admin').first()
if not admin:
    admin = User.objects.create_superuser(username='admin', password='password123', email='admin@test.com')

print('Users ready.')
MainPass.objects.all().delete()
UsageLog.objects.all().delete()

# Test Apply Pass via Client
c.login(username='student1', password='password123')
c.post('/passes/apply/')
pending_pass = MainPass.objects.get(user=student)
print(f'Student applied. Status: {pending_pass.status}')

# Test Approve Pass via Client
c.login(username='admin', password='password123')
c.post(f'/passes/approve/{pending_pass.pk}/')
approved_pass = MainPass.objects.get(user=student)
print(f'Admin approved. Status: {approved_pass.status}, ID: {approved_pass.main_pass_id}')

# Scan Pass (API) - Expect No Renewal error
import datetime
from django.utils import timezone
response0 = c.post('/api/scan/', json.dumps({'main_pass_id': approved_pass.main_pass_id, 'device_id': 'Bus1'}), content_type='application/json')
print(f'Scan 0 (No Renewal): {response0.json()}')

MonthlyRenewal.objects.create(main_pass=approved_pass, month='MAR', valid_from=timezone.now().date(), valid_to=timezone.now().date() + datetime.timedelta(days=30))

response1 = c.post('/api/scan/', json.dumps({'main_pass_id': approved_pass.main_pass_id, 'device_id': 'Bus1'}), content_type='application/json')
print(f'Scan 1 with renewal: {response1.json()}')

response2 = c.post('/api/scan/', json.dumps({'main_pass_id': approved_pass.main_pass_id, 'device_id': 'Bus1'}), content_type='application/json')
print(f'Scan 2 with renewal: {response2.json()}')

response3 = c.post('/api/scan/', json.dumps({'main_pass_id': approved_pass.main_pass_id, 'device_id': 'Bus1'}), content_type='application/json')
print(f'Scan 3 with renewal (should fail): {response3.json()}')

