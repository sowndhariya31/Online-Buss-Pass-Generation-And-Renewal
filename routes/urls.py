from django.urls import path
from . import views

urlpatterns = [
    path('manage/', views.manage_routes, name='manage_routes'),
    path('add/', views.add_route, name='add_route'),
    path('delete/<int:pk>/', views.delete_route, name='delete_route'),
    path('find/', views.find_route, name='find_route'),
]
