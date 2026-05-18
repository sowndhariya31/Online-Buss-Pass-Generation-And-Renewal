from django.urls import path
from . import api

urlpatterns = [
    path('list/', api.BusRouteListAPIView.as_view(), name='api_routes_list'),
]
