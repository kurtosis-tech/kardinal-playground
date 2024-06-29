FROM python:3.9-slim

WORKDIR /app

COPY . .

RUN pip install Flask redis psycopg2-binary

EXPOSE 5000

CMD ["python", "app.py"]

