FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBUG=False

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    net-tools \ 
    iputils-ping \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app

USER appuser

RUN python manage.py collectstatic --noinput

EXPOSE 8000


CMD ["gunicorn", "bankingsystem.wsgi:application", "--bind", "0.0.0.0:8000"]