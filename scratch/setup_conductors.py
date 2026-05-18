from users.models import User
data = [('588', 'cond588@bus.local'), ('21G', 'cond21g@bus.local'), ('47A', 'cond47a@bus.local')]
for bus, email in data:
    u, created = User.objects.get_or_create(email=email, defaults={'username': email, 'role': 'CONDUCTOR', 'bus_number': bus})
    u.set_password('pass123')
    u.role = 'CONDUCTOR'
    u.bus_number = bus
    u.phone = f"999999{bus[:4].ljust(4, '0')}"[:10] # Dummy unique phone
    u.save()
    print(f'Set up conductor for bus {bus}')
