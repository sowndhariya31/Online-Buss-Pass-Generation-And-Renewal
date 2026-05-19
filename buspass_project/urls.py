from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from users.api import CustomTokenObtainPairView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('users.urls')),
    path('passes/', include('passes.urls')),
    path('routes/', include('routes.urls')),
    path('api/scan/', include('api.urls')),
    path('api/token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/users/', include('users.api_urls')),
    path('api/passes/', include('passes.api_urls')),
    path('api/routes/', include('routes.api_urls')),
]

from django.urls import re_path
from django.views.static import serve

# Unconditionally serve media files so they are visible in production (Render)
urlpatterns += [
    re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT, 'show_indexes': True}),
]
