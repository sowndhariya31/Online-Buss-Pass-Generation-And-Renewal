from rest_framework import generics, permissions, serializers
from rest_framework.response import Response
from .serializers import RegisterSerializer, UserSerializer
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Make email not required since we might use bus_number
        self.fields['email'] = serializers.EmailField(required=False)
        self.fields['bus_number'] = serializers.CharField(required=False)

    def validate(self, attrs):
        bus_number = attrs.get('bus_number').strip() if attrs.get('bus_number') else None
        email = attrs.get('email').strip() if attrs.get('email') else None
        password = attrs.get('password')
        
        user = None
        if bus_number:
            user = User.objects.filter(bus_number__iexact=bus_number, role='CONDUCTOR').first()
        elif email:
            user = User.objects.filter(email__iexact=email).first()
            if not user:
                user = User.objects.filter(username__iexact=email).first()
            
        if user and user.check_password(password):
            # Manually provide the tokens so we don't rely on super().validate which might fail
            # if it tries to re-authenticate with the original email/bus_number field.
            refresh = self.get_token(user)
            
            return {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        
        identifier = bus_number if bus_number else email
        raise serializers.ValidationError(f'Invalid credentials for {identifier}.')

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class RegisterAPIView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

class UserProfileAPIView(generics.RetrieveAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

class UserListAPIView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = (permissions.IsAdminUser,)

    def get_queryset(self):
        role = self.request.query_params.get('role')
        if role:
            return User.objects.filter(role=role)
        return User.objects.all()
