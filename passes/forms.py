from django import forms
from .models import MainPass, MonthlyRenewal
from users.models import User

class ApplyPassForm(forms.ModelForm):
    class Meta:
        model = MainPass
        fields = ['pass_type']

class PassDetailForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['college', 'address', 'route_from', 'route_to', 'photo', 'id_proof']

