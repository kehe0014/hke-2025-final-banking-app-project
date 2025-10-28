"""bankingsystem URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.11/topics/http/urls/
"""
from django.conf import settings
from django.conf.urls import url, include
from django.conf.urls.static import static
from django.contrib import admin

from core.views import home, about, health_check

urlpatterns = [
    # admin
    url(r'^admin/', admin.site.urls),
    # Accounts
    url(r'^accounts/', include('accounts.urls', namespace='accounts')),
    # core
    url(r'^$', home, name='home'),
    url(r'^about/$', about, name='about'),
    url(r'^health-check/$', health_check, name='health_check'),
    # transactions
    url(r'^', include('transactions.urls', namespace='transactions')),
]

# Servir les fichiers statiques en développement
if settings.DEBUG:
    urlpatterns += static(
        settings.STATIC_URL,
        document_root=settings.STATIC_ROOT
    )
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT
    )