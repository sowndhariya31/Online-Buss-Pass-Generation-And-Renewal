from django import forms
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.core.exceptions import ValidationError
from .models import User

class CustomUserCreationForm(UserCreationForm):
    class Meta:
        model = User
        fields = ('username', 'email', 'phone')

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['email'].required = True
        self.fields['phone'].required = True
        self.fields['phone'].widget.attrs.update({
            'pattern': '[0-9]{10}',
            'maxlength': '10',
            'minlength': '10',
            'title': 'Please enter exactly 10 digits'
        })

    def clean_email(self):
        email = self.cleaned_data.get('email')
        if User.objects.filter(email=email).exists():
            raise ValidationError("A user with this email already exists.")
        return email

    def clean_phone(self):
        phone = self.cleaned_data.get('phone')
        if not phone:
            raise ValidationError("Phone number is required.")
        if not phone.isdigit():
            raise ValidationError("Phone number must contain exactly 10 digits.")
        if len(phone) != 10:
            raise ValidationError("Phone number must be exactly 10 digits.")
        if User.objects.filter(phone=phone).exists():
            raise ValidationError("A user with this phone number already exists.")
        return phone

class EmailAuthenticationForm(AuthenticationForm):
    username = forms.EmailField(label="Email", widget=forms.EmailInput(attrs={'autofocus': True}))
