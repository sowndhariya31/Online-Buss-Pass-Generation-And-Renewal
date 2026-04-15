from django.urls import path
from . import views

urlpatterns = [
    path('apply/', views.apply_pass, name='apply_pass'),
    path('renew/<int:pk>/', views.renew_pass, name='renew_pass'),
    path('approve/<int:pk>/', views.approve_pass, name='approve_pass'),
    path('download/<int:pk>/', views.download_pass, name='download_pass'),
    path('pay/<int:pk>/', views.pay_pass, name='pay_pass'),
    path('pay-renewal/<int:pk>/', views.pay_renewal, name='pay_renewal'),
    path('download-id/<int:pk>/', views.download_id_card, name='download_id_card'),
    path('renew-search/', views.renew_search_view, name='renew_search'),
    path('scanner/', views.scanner_view, name='scanner'),
    path('edit/<int:pk>/', views.edit_pass_view, name='edit_pass'),
    path('delete/<int:pk>/', views.delete_pass_view, name='delete_pass'),
    path('test-pay/', views.test_razorpay, name='test_pay'),
]
