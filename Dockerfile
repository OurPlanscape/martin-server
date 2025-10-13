FROM ghcr.io/maplibre/martin:martin-v0.19.3

ENV PYTHONUNBUFFERED True
ENV APP_HOME /app

ADD . /app
WORKDIR /app

EXPOSE 3000
CMD ["martin", "--config", "martin.yml"]
