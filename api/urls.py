from django.urls import path
from . import views

urlpatterns = [
    path('scan/', views.scan_pass, name='scan_pass'),
]
