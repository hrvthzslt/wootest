cp .env.example .env

docker compose down -v

if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

docker compose up wp -d
docker compose up pma -d

until [ "`docker inspect -f {{.State.Health.Status}} db`" == "healthy" ]; do
sleep 0.1;
done;

docker compose run --rm wpcli wp core install \
    --url=$APP_URL \
    --title=$APP_TITLE \
    --admin_user=$ADMIN_USER \
    --admin_password=$ADMIN_PASSWORD \
    --admin_email=$ADMIN_EMAIL