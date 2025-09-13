FROM python:3-slim-bookworm

WORKDIR /app

COPY ./requirements.txt .

RUN pip install -r requirements.txt

COPY ./webapp/ ./webapp

EXPOSE 5000

CMD ["python", "./webapp/app.py"]
