from django.urls import path
from . import views

urlpatterns = [
    path('', views.home_view, name='home'),
    path('login/', views.login_view, name='login'),
    path('register/', views.register_view, name='register'),
    path('logout/', views.logout_view, name='logout'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('user/edit/<int:pk>/', views.edit_user_view, name='edit_user'),
    path('user/delete/<int:pk>/', views.delete_user_view, name='delete_user'),
]
