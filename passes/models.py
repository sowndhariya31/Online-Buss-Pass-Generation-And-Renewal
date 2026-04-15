from django.db import models
from django.conf import settings

class MainPass(models.Model):
    STATUS_CHOICES = (
        ('ACTIVE', 'Active'),
        ('BLOCKED', 'Blocked'),
        ('EXPIRED', 'Expired'),
        ('PENDING', 'Pending'),  # Added pending for approval flow
    )
    PASS_TYPE_CHOICES = (
        ('STUDENT', 'Student'),
        ('PUBLIC', 'Public'),
    )
    PAYMENT_STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('PAID', 'Paid')
    )

    main_pass_id = models.CharField(max_length=20, unique=True, blank=True, null=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='main_passes')
    pass_type = models.CharField(max_length=10, choices=PASS_TYPE_CHOICES)
    issue_date = models.DateField(auto_now_add=True)
    expiry_date = models.DateField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING')
    payment_status = models.CharField(max_length=10, choices=PAYMENT_STATUS_CHOICES, default='PENDING')
    
    # SRD Daily Usage Logic
    daily_trip_count = models.IntegerField(default=0)
    last_used_date = models.DateField(null=True, blank=True)
    current_valid_to = models.DateField(null=True, blank=True)

    @property
    def is_currently_valid(self):
        from django.utils import timezone
        today = timezone.now().date()
        if self.status != 'ACTIVE':
            return False
            
        # Check if there is a paid renewal for the current month
        current_month = today.strftime('%b').upper()
        renewal = self.renewals.filter(month=current_month, payment_status='PAID').first()
        if not renewal:
            return False
            
        if renewal.valid_to < today:
            return False
            
        return True

    def generate_pass_id(self):
        """Generate and assign a unique pass ID. Call only after payment."""
        if self.main_pass_id:
            return  # Already has an ID
        from django.utils import timezone
        import time
        year = timezone.now().year
        prefix = "MTC" if self.pass_type == 'STUDENT' else "PUB"
        
        attempts = 0
        while attempts < 5:
            last_pass = MainPass.objects.filter(main_pass_id__startswith=f"{prefix}{year}").order_by('-main_pass_id').first()
            
            if last_pass:
                try:
                    last_id_str = last_pass.main_pass_id.split('-')[-1]
                    last_id = int(last_id_str)
                    new_id = last_id + 1
                except (ValueError, IndexError):
                    new_id = 1
            else:
                new_id = 1
            
            potential_id = f"{prefix}{year}-{new_id:06d}"
            
            if not MainPass.objects.filter(main_pass_id=potential_id).exists():
                self.main_pass_id = potential_id
                break
            
            attempts += 1
            time.sleep(0.1)
        
        self.save()

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.main_pass_id} - {self.user.username} ({self.pass_type})"


class MonthlyRenewal(models.Model):
    PAYMENT_STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('PAID', 'Paid')
    )
    main_pass = models.ForeignKey(MainPass, on_delete=models.CASCADE, related_name='renewals')
    month = models.CharField(max_length=10) # e.g. JAN, FEB
    renewal_date = models.DateField(auto_now_add=True)
    valid_from = models.DateField()
    valid_to = models.DateField()
    payment_status = models.CharField(max_length=10, choices=PAYMENT_STATUS_CHOICES, default='PENDING')
    renewal_id = models.CharField(max_length=50, unique=True, null=True, blank=True)

    class Meta:
        unique_together = ('main_pass', 'month')

    def __str__(self):
        return f"Renewal {self.main_pass.main_pass_id} for {self.month} ({self.payment_status})"

    def generate_renewal_id(self):
        """Generate and assign a unique renewal ID. Call only after renewal payment."""
        if self.renewal_id:
            return  # Already has an ID
        
        from django.utils import timezone
        import time
        year = timezone.now().year
        prefix = "REN"
        
        attempts = 0
        while attempts < 5:
            last_renewal = MonthlyRenewal.objects.filter(renewal_id__startswith=f"{prefix}{year}").order_by('-renewal_id').first()
            
            if last_renewal and last_renewal.renewal_id:
                try:
                    last_id_str = last_renewal.renewal_id.split('-')[-1]
                    last_id = int(last_id_str)
                    new_id = last_id + 1
                except (ValueError, IndexError):
                    new_id = 1
            else:
                new_id = 1
            
            potential_id = f"{prefix}{year}-{new_id:06d}"
            
            if not MonthlyRenewal.objects.filter(renewal_id=potential_id).exists():
                self.renewal_id = potential_id
                break
            
            attempts += 1
            time.sleep(0.1)
        
        self.save()


class UsageLog(models.Model):
    main_pass = models.ForeignKey(MainPass, on_delete=models.CASCADE, related_name='usage_logs')
    scan_time = models.DateTimeField(auto_now_add=True)
    trip_number = models.IntegerField()
    device_id = models.CharField(max_length=50, blank=True, null=True)

    def __str__(self):
        return f"Log {self.id} for {self.main_pass.main_pass_id} (Trip {self.trip_number})"
