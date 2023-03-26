FROM minio/console:v0.25.0

COPY ./ca-trust/ /etc/pki/ca-trust/extracted/pem/ca-trust/

RUN cd /etc/pki/ca-trust/extracted/pem/ca-trust && bash add.sh && cd .. && rm -rf ca-trust