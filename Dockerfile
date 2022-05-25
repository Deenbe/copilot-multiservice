FROM python:3.8.3-slim-buster
WORKDIR /app
COPY app.py ./
COPY index.html ./
COPY requirements.txt ./
RUN pip install -r requirements.txt
EXPOSE 9090
CMD [ "python", "app.py"]
