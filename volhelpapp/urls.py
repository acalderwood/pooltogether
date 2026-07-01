from django.urls import path
from . import views

urlpatterns = [
    path('signup/', views.volunteer_signup, name='volunteer_signup'),
]
