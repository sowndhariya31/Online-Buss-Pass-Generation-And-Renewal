import os
import django
import re

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from users.models import User

content = open('templates/routes/find_route.html', encoding='utf-8').read()
matches = re.findall(r'no:\s*\"(.*?)\",\s*start:\s*\"(.*?)\",\s*end:\s*\"(.*?)\"', content)

for no, start, end in matches:
    email = f"cond_{no.lower().replace('.', '_')}@bus.local"
    u, created = User.objects.get_or_create(
        email=email, 
        defaults={
            'username': f"Conductor {no}",
            'role': 'CONDUCTOR',
            'bus_number': no,
            'bus_route': f"{start} - {end}",
            'phone': f"90000{no[:5].ljust(5, '0')}"[:10]
        }
    )
    u.set_password('pass123')
    u.role = 'CONDUCTOR'
    u.bus_number = no
    u.bus_route = f"{start} - {end}"
    u.save()
    print(f"Created/Updated Conductor for Bus {no}: {email}")
