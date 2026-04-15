from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    ROLE_CHOICES = (
        ('STUDENT', 'Student'),
        ('PUBLIC', 'Public'),
        ('ADMIN', 'Admin'),
        ('CONDUCTOR', 'Conductor'),
    )
    
    # Enforce uniqueness on email and phone
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=15, unique=True, blank=False, null=False)
    
    # Allow duplicate usernames (using email as login identifier instead)
    username = models.CharField(max_length=150, unique=False)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'phone']
    
    role = models.CharField(max_length=15, choices=ROLE_CHOICES, default='STUDENT')
    
    # New SRD Fields
    college = models.CharField(max_length=200, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    route = models.CharField(max_length=100, blank=True, null=True) 
    
    photo = models.ImageField(upload_to='photos/', null=True, blank=True)
    id_proof = models.ImageField(upload_to='id_proofs/', null=True, blank=True)

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
