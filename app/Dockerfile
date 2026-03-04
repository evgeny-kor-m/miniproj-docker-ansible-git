FROM evgenykorchev/ansible-slave-image:v01

WORKDIR /app

COPY requirements.txt .

RUN apt-get update 

COPY app/src/app_slave.py .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["tail", "-f", "/dev/null"]