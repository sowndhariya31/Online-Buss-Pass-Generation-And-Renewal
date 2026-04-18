from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login, logout, authenticate
from django.contrib.auth.decorators import login_required
from .forms import CustomUserCreationForm, EmailAuthenticationForm
from passes.models import MainPass, UsageLog
from django.contrib import messages

def home_view(request):
    return render(request, 'home.html')

def register_view(request):
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST, request.FILES)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('dashboard')
    else:
        form = CustomUserCreationForm()
    return render(request, 'users/register.html', {'form': form})

def login_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')
        
    if request.method == 'POST':
        form = EmailAuthenticationForm(data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            return redirect('dashboard')
    else:
        form = EmailAuthenticationForm()
    return render(request, 'users/login.html', {'form': form})

def logout_view(request):
    if request.method == "POST":
        logout(request)
        return redirect('login')
    # fallback if accessed via GET
    logout(request)
    return redirect('login')

@login_required
def dashboard_view(request):
    context = {}
    
    # User's own passes
    passes = MainPass.objects.filter(user=request.user).order_by('-issue_date')
    context['passes'] = passes
    
    # Admin sections (only if user is admin/staff)
    if request.user.role == 'ADMIN' or request.user.is_superuser or request.user.is_staff:
        # Search Queries
        q_student = request.GET.get('q_student', '')
        q_public = request.GET.get('q_public', '')
        q_pass = request.GET.get('q_pass', '')

        # Pending Passes (usually not filtered for simplicity but could be)
        pending_student_passes = MainPass.objects.filter(status='PENDING', pass_type='STUDENT').order_by('-issue_date')
        pending_public_passes = MainPass.objects.filter(status='PENDING', pass_type='PUBLIC').order_by('-issue_date')
        
        total_passes = MainPass.objects.count()
        active_passes = MainPass.objects.filter(status='ACTIVE').count()
        
        # Separate student vs public counts
        student_passes = MainPass.objects.filter(pass_type='STUDENT').count()
        public_passes = MainPass.objects.filter(pass_type='PUBLIC').count()
        active_student = MainPass.objects.filter(pass_type='STUDENT', status='ACTIVE').count()
        active_public = MainPass.objects.filter(pass_type='PUBLIC', status='ACTIVE').count()
        
        # Separate revenue calculation
        from passes.models import MonthlyRenewal
        renewals = MonthlyRenewal.objects.all()
        student_revenue = 0
        public_revenue = 0
        for r in renewals:
            if r.main_pass.pass_type == 'STUDENT':
                student_revenue += 280
            else:
                public_revenue += 1000
        total_revenue = student_revenue + public_revenue
                
        recent_logs = UsageLog.objects.all().order_by('-scan_time')[:10]
        
        # Fetch registered users separated by type + Search
        from users.models import User
        student_users = User.objects.filter(role='STUDENT').order_by('username')
        if q_student:
            student_users = student_users.filter(username__icontains=q_student) | \
                           student_users.filter(first_name__icontains=q_student) | \
                           student_users.filter(last_name__icontains=q_student) | \
                           student_users.filter(college__icontains=q_student)
            
        public_users = User.objects.filter(role='PUBLIC').order_by('username')
        if q_public:
            public_users = public_users.filter(username__icontains=q_public) | \
                          public_users.filter(first_name__icontains=q_public) | \
                          public_users.filter(last_name__icontains=q_public) | \
                          public_users.filter(address__icontains=q_public)
        
        # All active passes for admin table + Search
        all_passes = MainPass.objects.exclude(status='PENDING').order_by('-issue_date')
        if q_pass:
            all_passes = all_passes.filter(main_pass_id__icontains=q_pass) | \
                         all_passes.filter(user__username__icontains=q_pass)
        
        # Determine active tab based on search
        active_tab = 'tab-pending-student'
        if q_student: active_tab = 'tab-student-users'
        elif q_public: active_tab = 'tab-public-users'
        elif q_pass: active_tab = 'tab-all-passes'

        pending_count = pending_student_passes.count() + pending_public_passes.count()
        context.update({
            'is_admin': True,
            'active_tab': active_tab,
            'pending_count': pending_count,
            'pending_student_passes': pending_student_passes,
            'pending_public_passes': pending_public_passes,
            'total_passes': total_passes,
            'active_passes': active_passes,
            'student_passes': student_passes,
            'public_passes': public_passes,
            'active_student': active_student,
            'active_public': active_public,
            'student_revenue': student_revenue,
            'public_revenue': public_revenue,
            'total_revenue': total_revenue,
            'recent_logs': recent_logs,
            'student_users': student_users,
            'public_users': public_users,
            'all_passes': all_passes,
            'q_student': q_student,
            'q_public': q_public,
            'q_pass': q_pass,
        })
    
    return render(request, 'users/dashboard.html', context)

@login_required
def edit_user_view(request, pk):
    from users.models import User
    if not (request.user.role == 'ADMIN' or request.user.is_superuser):
        return redirect('dashboard')
    
    user_to_edit = get_object_or_404(User, pk=pk)
    if request.method == 'POST':
        user_to_edit.first_name = request.POST.get('first_name', user_to_edit.first_name)
        user_to_edit.last_name = request.POST.get('last_name', user_to_edit.last_name)
        user_to_edit.phone = request.POST.get('phone', user_to_edit.phone)
        user_to_edit.college = request.POST.get('college', user_to_edit.college)
        user_to_edit.address = request.POST.get('address', user_to_edit.address)
        user_to_edit.route_from = request.POST.get('route_from', user_to_edit.route_from)
        user_to_edit.route_to = request.POST.get('route_to', user_to_edit.route_to)
        user_to_edit.save()
        messages.success(request, f"User {user_to_edit.username} updated successfully.")
        return redirect('dashboard')
    
    return render(request, 'users/edit_user.html', {'u': user_to_edit})

@login_required
def delete_user_view(request, pk):
    from users.models import User
    if not (request.user.role == 'ADMIN' or request.user.is_superuser):
        return redirect('dashboard')
    
    user_to_del = get_object_or_404(User, pk=pk)
    username = user_to_del.username
    user_to_del.delete()
    messages.warning(request, f"User {username} has been dropped.")
    return redirect('dashboard')

