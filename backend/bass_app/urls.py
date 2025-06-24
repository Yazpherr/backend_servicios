from django.urls import path, include
from rest_framework import routers
from .views import ItemViewSet, UserViewSet

router = routers.DefaultRouter()
router.register(r'items', ItemViewSet, basename='item')
router.register(r'users', UserViewSet, basename='user')

urlpatterns = [
    path('', include(router.urls)),
]
