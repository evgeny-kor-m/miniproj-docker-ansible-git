FROM python:3.8-slim

WORKDIR /app

COPY ./app/requirements.txt .

RUN apt-get update && apt-get install -y \
    sudo \
    iputils-ping\
    netcat-openbsd
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app .

EXPOSE 5000

CMD  ["python","src/app_crm.py"]
