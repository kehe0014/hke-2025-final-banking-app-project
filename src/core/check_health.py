from django.http import JsonResponse
from django.db import connection
from django.core.cache import cache

def health_check(request):
    """Health check endpoint for Kubernetes"""
    try:
        # Vérifier la base de données
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        # Vérifier le cache Redis
        cache.set('health_check', 'ok', 5)
        if cache.get('health_check') != 'ok':
            raise Exception("Cache not working")
        
        return JsonResponse({
            "status": "healthy",
            "database": "ok",
            "cache": "ok"
        })
    except Exception as e:
        return JsonResponse({
            "status": "unhealthy",
            "error": str(e)
        }, status=500)