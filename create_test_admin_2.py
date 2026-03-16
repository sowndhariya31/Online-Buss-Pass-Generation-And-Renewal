import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from users.models import User

username = 'admin_test'
email = 'admin@example.com'
password = 'password123'

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username, email, password, role='ADMIN')
    print(f"User {username} created successfully.")
else:
    print(f"User {username} already exists.")
