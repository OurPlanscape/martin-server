FROM python:3.14.0-slim-trixie

ENV MARTIN_URL=https://github.com/maplibre/martin/releases/download/martin-v0.19.3/martin-x86_64-unknown-linux-gnu.tar.gz
ENV CLOUDSQL_AUTH_URL=https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.18.2/cloud-sql-proxy.linux.amd64
ENV PYTHONUNBUFFERED True
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y && apt install -y \
    curl \
    wget \ 
    openssh-client \
    libcurl4-openssl-dev \ 
    libssl-dev \
    ca-certificates

RUN mkdir -p /martin && \
    wget -q -O /martin/martin.tar.gz "$MARTIN_URL" && \
    tar -xvf /martin/martin.tar.gz -C /martin

COPY martin.yaml /martin/martin.yaml

EXPOSE 3000
CMD ["/martin/martin", "--config", "/martin/martin.yaml"]