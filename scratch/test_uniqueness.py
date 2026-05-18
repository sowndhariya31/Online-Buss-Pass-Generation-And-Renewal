import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

email = 'test_unique@example.com'
try:
    User.objects.create_user(username='u1', email=email, password='password123', phone='9999999991')
    print(f"Created first user with {email}")
    User.objects.create_user(username='u2', email=email, password='password123', phone='9999999992')
    print(f"Created second user with {email} (Wait, this shouldn't happen!)")
except Exception as e:
    print(f"Caught expected error: {e}")
finally:
    User.objects.filter(email=email).delete()
