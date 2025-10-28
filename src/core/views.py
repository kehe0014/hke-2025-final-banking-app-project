from django.db.models import Sum
from django.shortcuts import render
from django.http import JsonResponse
from django.db import connection
from django.core.cache import cache

from transactions.models import Diposit, Withdrawal, Interest


def home(request):
    if not request.user.is_authenticated:
        return render(request, "core/index.html", {})
    else:
        user = request.user
        deposit = Diposit.objects.filter(user=user)
        deposit_sum = deposit.aggregate(Sum('amount'))['amount__sum']
        withdrawal = Withdrawal.objects.filter(user=user)
        withdrawal_sum = withdrawal.aggregate(Sum('amount'))['amount__sum']
        interest = Interest.objects.filter(user=user)
        interest_sum = interest.aggregate(Sum('amount'))['amount__sum']

        context = {
                    "user": user,
                    "deposit": deposit,
                    "deposit_sum": deposit_sum,
                    "withdrawal": withdrawal,
                    "withdrawal_sum": withdrawal_sum,
                    "interest": interest,
                    "interest_sum": interest_sum,
                  }

        return render(request, "core/transactions.html", context)


def about(request):
    return render(request, "core/about.html", {})


def health_check(request): 
    """Health check endpoint for Kubernetes"""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        return JsonResponse({
            "status": "healthy",
            "database": "ok",
            "service": "banking-app"
        })
    except Exception as e:
        return JsonResponse({
            "status": "unhealthy",
            "error": str(e)
        }, status=500)