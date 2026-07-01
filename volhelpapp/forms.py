from django import forms
from .models import Volunteer

class VolunteerSignupForm(forms.ModelForm):
    class Meta:
        model = Volunteer
        fields = [
            'first_name', 'last_name', 'email', 'phone', 'dob',
            'borough', 'address_line1', 'address_line2',
            'county', 'postcode', 'areas_of_interest'
        ]
        widgets = {
            'dob': forms.DateInput(
                attrs={'type': 'date'},
                format='%d/%m/%Y'
            ),
            'areas_of_interest': forms.CheckboxSelectMultiple,
        }
        labels = {
            'areas_of_interest': 'Areas of Interest (Select all that apply)',
        }
        help_texts = {
            'phone': 'Optional',
            'dob': 'Optional',
            'address_line1': 'Optional',
            'address_line2': 'Optional',
            'county': 'Optional',
            'postcode': 'Optional',
        }
