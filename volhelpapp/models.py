from django.db import models

class VolunteerOpportunity(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name

class Volunteer(models.Model):
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    dob = models.DateField(blank=True, null=True)
    borough = models.CharField(max_length=100)
    address_line1 = models.CharField(max_length=200, blank=True, null=True)
    address_line2 = models.CharField(max_length=200, blank=True, null=True)
    county = models.CharField(max_length=100, blank=True, null=True)
    postcode = models.CharField(max_length=20, blank=True, null=True)
    areas_of_interest = models.ManyToManyField(VolunteerOpportunity, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
