import os
from django.core.management.base import BaseCommand
from users.models import User

class Command(BaseCommand):
    help = 'Creates a default admin user for Render deployment'

    def handle(self, *args, **options):
        email = 'admin@27gmail.com'
        password = 'admin2722'
        
        if not User.objects.filter(email=email).exists():
            User.objects.create_superuser(
                email=email,
                username='Admin',
                password=password,
                phone='0000000000',
                role='ADMIN'
            )
            self.stdout.write(self.style.SUCCESS(f'Successfully created admin user: {email}'))
        else:
            self.stdout.write(self.style.WARNING(f'Admin user {email} already exists'))
