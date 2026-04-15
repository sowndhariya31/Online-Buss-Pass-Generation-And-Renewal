from django.db import models

class Route(models.Model):
    route_name = models.CharField(max_length=100)
    from_location = models.CharField(max_length=100)
    to_location = models.CharField(max_length=100)
    price = models.DecimalField(max_digits=8, decimal_places=2)

    def __str__(self):
        return f"{self.route_name}: {self.from_location} to {self.to_location}"
