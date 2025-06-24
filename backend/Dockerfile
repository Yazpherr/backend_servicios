FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# Instala Django y DRF
RUN pip install django djangorestframework psycopg2-binary gunicorn

# Copiamos sólo el entrypoint y requirements (ya instaladas)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Una vez creado el proyecto, usaremos Gunicorn
CMD ["gunicorn", "bass.wsgi:application", "--bind", "0.0.0.0:8000"]
