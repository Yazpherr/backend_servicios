from django.urls import path, include
from rest_framework import routers
from .views import ItemViewSet  # o la vista que hayas definido

router = routers.DefaultRouter()
router.register(r'items', ItemViewSet, basename='item')

urlpatterns = [
    path('', include(router.urls)),
]
