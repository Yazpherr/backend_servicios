from django.shortcuts import render

from rest_framework import viewsets
from .models import Item
from .serializers import ItemSerializer

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
