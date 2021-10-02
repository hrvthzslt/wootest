echo "###########################################"
echo "# Cleaning wp-app, wp-data, volumes, .env #"
echo "###########################################"
printf "/n/n"

sudo rm -rf wp-app
sudo rm -rf wp-data

cp -r .env.example .env

docker compose down -v

if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

echo "#####################"
echo "# Starting services #"
echo "#####################"
printf "/n/n"

docker compose up wp -d
docker compose up pma -d

until [ "`docker inspect -f {{.State.Health.Status}} db`" == "healthy" ]; do
  sleep 0.1;
done;

echo "########################"
echo "# Installing wordpress #"
echo "########################"
printf "/n/n"

docker compose run --rm wpcli wp core install \
    --url=$APP_URL \
    --title=$APP_TITLE \
    --admin_user=$ADMIN_USER \
    --admin_password=$ADMIN_PASSWORD \
    --admin_email=$ADMIN_EMAIL

echo "################################################"
echo "# Installing woocommerce with storefront theme #"
echo "################################################"
printf "/n/n"

docker compose run --rm wpcli wp plugin install woocommerce --activate
docker compose run --rm wpcli wp theme install storefront --activate

echo "##################"
echo "# Importing data #"
echo "##################"

docker cp "wordpress.sql" wp:"/var/www/html/wordpress.sql"
docker compose run --rm wpcli wp db import wordpress.sql