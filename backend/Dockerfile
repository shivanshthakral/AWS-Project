FROM python:3.11-slim

WORKDIR /app
COPY backend/requirements.txt /app/requirements.txt
RUN for attempt in 1 2 3; do \
      pip install --retries 8 --timeout 60 -r /app/requirements.txt && break; \
      if [ "$attempt" -eq 3 ]; then exit 1; fi; \
      sleep 5; \
    done \
    && rm -rf /root/.cache/pip

COPY backend /app
COPY frontend /frontend

ENV PYTHONUNBUFFERED=1
EXPOSE 5001
CMD ["sh", "-c", "python -c 'from app import create_app; create_app()' && exec gunicorn --bind 0.0.0.0:5001 --workers 2 --access-logfile - 'app:create_app()'"]
