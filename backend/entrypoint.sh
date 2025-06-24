#!/bin/sh
set -e

# Si no existe manage.py => arranca el proyecto Django
if [ ! -f /app/manage.py ]; then
  echo "🛠 Iniciando proyecto Django..."
  django-admin startproject bass /app
fi

# Corre migraciones y collectstatic
echo "Aplicando migraciones..."
python /app/manage.py migrate --noinput

echo "Recolectando archivos estáticos..."
python /app/manage.py collectstatic --noinput

# Finalmente, ejecuta el CMD del Dockerfile
exec "$@"
