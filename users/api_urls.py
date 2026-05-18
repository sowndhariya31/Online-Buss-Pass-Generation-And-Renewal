from django.urls import path
from . import api

urlpatterns = [
    path('register/', api.RegisterAPIView.as_view(), name='api_register'),
    path('profile/', api.UserProfileAPIView.as_view(), name='api_profile'),
    path('list/', api.UserListAPIView.as_view(), name='api_user_list'),
]
