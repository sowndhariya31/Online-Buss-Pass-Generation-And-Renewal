from rest_framework import generics, permissions
from .models import Route
from .serializers import RouteSerializer

class BusRouteListAPIView(generics.ListAPIView):
    queryset = Route.objects.all()
    serializer_class = RouteSerializer
    permission_classes = (permissions.AllowAny,)
    
    def get_queryset(self):
        queryset = Route.objects.all()
        q = self.request.query_params.get('q', None)
        if q is not None:
            queryset = queryset.filter(route_name__icontains=q)
        return queryset
