from rest_framework import serializers
from .models import MainPass, MonthlyRenewal

class MainPassSerializer(serializers.ModelSerializer):
    user_email = serializers.ReadOnlyField(source='user.email')
    username = serializers.ReadOnlyField(source='user.username')
    user_phone = serializers.ReadOnlyField(source='user.phone')
    college_name = serializers.ReadOnlyField(source='user.college')
    route_from = serializers.ReadOnlyField(source='user.route_from')
    route_to = serializers.ReadOnlyField(source='user.route_to')
    user_address = serializers.ReadOnlyField(source='user.address')
    user_photo = serializers.SerializerMethodField()
    user_id_proof = serializers.SerializerMethodField()
    daily_trip_count = serializers.SerializerMethodField()

    is_currently_valid = serializers.ReadOnlyField()
    active_renewal_id = serializers.ReadOnlyField()
    active_renewal_month = serializers.ReadOnlyField()

    class Meta:
        model = MainPass
        fields = [
            'id', 'main_pass_id', 'pass_type', 'issue_date', 'expiry_date', 
            'status', 'daily_trip_count', 'user_email', 'username', 'user_phone', 'college_name', 
            'route_from', 'route_to', 'user_address', 'user_photo', 'user_id_proof',
            'payment_status', 'is_currently_valid', 'current_valid_to',
            'active_renewal_id', 'active_renewal_month'
        ]

    def get_daily_trip_count(self, obj):
        from django.utils import timezone
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        return obj.usage_logs.filter(scan_time__gte=today_start).count()

    def get_user_photo(self, obj):
        request = self.context.get('request')
        if obj.user.photo:
            url = obj.user.photo.url
            if request:
                return request.build_absolute_uri(url)
            return url
        return None

    def get_user_id_proof(self, obj):
        request = self.context.get('request')
        if obj.user.id_proof:
            url = obj.user.id_proof.url
            if request:
                return request.build_absolute_uri(url)
            return url
        return None

class MonthlyRenewalSerializer(serializers.ModelSerializer):
    class Meta:
        model = MonthlyRenewal
        fields = ['renewal_id', 'valid_from', 'valid_to', 'payment_status', 'renewal_date']

class ApplyPassSerializer(serializers.ModelSerializer):
    class Meta:
        model = MainPass
        fields = ['pass_type']
        extra_kwargs = {'pass_type': {'required': False}}
