
docker run \
  docker.elastic.co/beats/filebeat:7.0.0-SNAPSHOT \
  setup -E "cloud.auth=$ELASTIC_CLOUD_CREDENTIALS" \
  -E "cloud.id=elastic:$ELASTIC_CLOUD_ID"

curl -L -O https://raw.githubusercontent.com/elastic/beats/6.6/deploy/docker/filebeat.docker.yml

docker run -d \
  --name=filebeat \
  --user=root \
  --volume="$(pwd)/filebeat.docker.yml:/usr/share/filebeat/filebeat.yml:ro" \
  --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  docker.elastic.co/beats/filebeat:7.0.0-SNAPSHOT \
  -e -strict.perms=false \
  -E cloud.id=$ELASTIC_CLOUD_ID \
  -E cloud.auth=$ELASTIC_CLOUD_CREDENTIALS


