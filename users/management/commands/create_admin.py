from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

class Command(BaseCommand):
    help = 'Create a superuser with hardcoded credentials'

    def handle(self, *args, **options):
        User = get_user_model()
        email = 'admin@27gmail.com'
        password = 'admin2722'
        username = 'admin27'
        phone = '1234567827'

        if not User.objects.filter(email=email).exists():
            User.objects.create_superuser(
                email=email,
                username=username,
                password=password,
                phone=phone,
                role='ADMIN'
            )
            self.stdout.write(self.style.SUCCESS(f'Successfully created superuser {email}'))
        else:
            self.stdout.write(self.style.WARNING(f'Superuser {email} already exists'))
