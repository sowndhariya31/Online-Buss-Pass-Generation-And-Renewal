import os
import sys
import django

sys.path.append('c:\\htmlproject\\buspass')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'buspass_project.settings')
django.setup()

from passes.models import MainPass

passes = MainPass.objects.all()
for p in passes:
    user = p.user
    print(f"Pass ID: {p.pk}")
    print(f"User Photo: {user.photo.name if user.photo else None}")
    print(f"User Photo URL: {user.photo.url if user.photo else None}")
    print(f"User ID Proof: {user.id_proof.name if user.id_proof else None}")
    print(f"User ID Proof URL: {user.id_proof.url if user.id_proof else None}")
