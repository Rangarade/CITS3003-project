# NEON//WIRE web portal (challenges 1-3). The XSS admin bot runs as a separate
# service (see docker-compose.yml) so this image stays small.
FROM python:3.11-slim
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ /app/
EXPOSE 8080
CMD ["python", "app.py"]
