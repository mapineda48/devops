export MINIO_ROOT_USER=""
export MINIO_ROOT_PASSWORD=""
export STORAGE_HOST=""
export MINIO_HOST=""

docker compose -f ./docker-compose.yml -f ./docker-compose.prod.yml up -d