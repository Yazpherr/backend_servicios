from django.shortcuts import render
from django.contrib.auth import get_user_model
from rest_framework import viewsets, permissions

from .models import Item
from .serializers import ItemSerializer, UserSerializer

User = get_user_model()

class ItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet para CRUD de Item:
    - GET     /api/items/        → lista items
    - POST    /api/items/        → crea un nuevo item
    - GET     /api/items/{pk}/   → detalle
    - PUT     /api/items/{pk}/   → actualiza
    - DELETE  /api/items/{pk}/   → elimina
    """
    # Queryset base: todos los Items
    queryset = Item.objects.all()
    # Serializer que convierte Item <→ JSON
    serializer_class = ItemSerializer

class UserViewSet(viewsets.ModelViewSet):
    """
    CRUD de usuarios:
      - GET    /api/users/       → lista usuarios
      - POST   /api/users/       → crea usuario
      - GET    /api/users/{id}/  → detalle
      - PUT    /api/users/{id}/  → actualiza
      - PATCH  /api/users/{id}/  → parches
      - DELETE /api/users/{id}/  → elimina
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve', 'create']:
            return [permissions.AllowAny()]
        return [permissions.IsAdminUser()]
