from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Route
from .forms import RouteForm

@login_required
def manage_routes(request):
    if request.user.role != 'admin':
        return redirect('dashboard')
    routes = Route.objects.all()
    return render(request, 'routes/manage.html', {'routes': routes})

@login_required
def add_route(request):
    if request.user.role != 'admin':
        return redirect('dashboard')
    if request.method == 'POST':
        form = RouteForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('manage_routes')
    else:
        form = RouteForm()
    return render(request, 'routes/add.html', {'form': form})

@login_required
def delete_route(request, pk):
    if request.user.role != 'admin':
        return redirect('dashboard')
    route = get_object_or_404(Route, pk=pk)
    if request.method == 'POST':
        route.delete()
        return redirect('manage_routes')
from django.conf import settings

@login_required
def find_route(request):
    conductor_bus_no = None
    if request.user.role == 'CONDUCTOR':
        conductor_bus_no = request.user.bus_number
    elif 'logged_in_bus_number' in request.session:
        conductor_bus_no = request.session['logged_in_bus_number']
        
    return render(request, 'routes/find_route.html', {
        'google_maps_api_key': settings.GOOGLE_MAPS_API_KEY,
        'conductor_bus_no': conductor_bus_no
    })
