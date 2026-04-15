from django.contrib import admin
from .models import MainPass, MonthlyRenewal, UsageLog

admin.site.register(MainPass)
admin.site.register(MonthlyRenewal)
admin.site.register(UsageLog)
