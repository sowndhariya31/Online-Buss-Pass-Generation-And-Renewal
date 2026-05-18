from django.urls import path
from . import api

urlpatterns = [
    path('list/', api.MainPassListAPIView.as_view(), name='api_passes_list'),
    path('<str:pass_id>/renewals/', api.MonthlyRenewalListAPIView.as_view(), name='api_renewals_list'),
    path('apply/', api.ApplyPassAPIView.as_view(), name='api_passes_apply'),
    path('admin/list/', api.AdminPassListAPIView.as_view(), name='api_admin_passes_list'),
    path('admin/<int:pk>/action/', api.AdminPassActionAPIView.as_view(), name='api_admin_pass_action'),
    path('<int:pk>/confirm_payment/', api.ConfirmPaymentAPIView.as_view(), name='api_confirm_payment'),
    path('<int:pk>/initiate_razorpay/', api.InitiateRazorpayAPIView.as_view(), name='api_initiate_razorpay'),
    path('confirm_razorpay/', api.VerifyRazorpayPaymentAPIView.as_view(), name='api_confirm_razorpay'),
    path('verify/<str:main_pass_id>/', api.VerifyPassAPIView.as_view(), name='api_verify_pass'),
    path('admin/logs/', api.UsageLogListAPIView.as_view(), name='api_admin_logs'),
]
