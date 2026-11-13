FROM python:3.11-slim

WORKDIR /app
COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY backend /app
COPY frontend /frontend

ENV PYTHONUNBUFFERED=1
EXPOSE 5001
CMD ["sh", "-c", "python -c 'from app import create_app; create_app()' && exec gunicorn --bind 0.0.0.0:5001 --workers 2 --access-logfile - 'app:create_app()'"]
