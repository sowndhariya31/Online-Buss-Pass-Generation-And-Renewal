import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from routes.models import Route

default_routes = [
    {"route_name": "Route A", "from_location": "City Center", "to_location": "University Campus", "price": 20.00},
    {"route_name": "Route B", "from_location": "North Station", "to_location": "South Station", "price": 15.00},
    {"route_name": "Route C", "from_location": "Main Square", "to_location": "Tech Park", "price": 25.00},
    {"route_name": "Route D", "from_location": "Airport", "to_location": "Downtown", "price": 50.00},
]

for r_data in default_routes:
    Route.objects.get_or_create(**r_data)

print("Successfully seeded default routes!")
