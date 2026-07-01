from django.shortcuts import render, redirect
from django.contrib import messages
from .forms import VolunteerSignupForm

def volunteer_signup(request):
    if request.method == 'POST':
        form = VolunteerSignupForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Thank you for signing up! We will contact you soon.')
            return redirect('volunteer_signup')
        else:
            messages.error(request, 'Please correct the errors below.')
    else:
        form = VolunteerSignupForm()

    return render(request, 'volhelpapp/volunteer_signup.html', {'form': form})
