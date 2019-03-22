#!/bin/bash

docker run \
  docker.elastic.co/beats/metricbeat:7.0.0-SNAPSHOT \
  setup -E "cloud.auth=$ELASTIC_CLOUD_CREDENTIALS" \
  -E "cloud.id=elastic:$ELASTIC_CLOUD_ID"

curl -L -O https://raw.githubusercontent.com/elastic/beats/master/deploy/docker/metricbeat.docker.yml


docker run -d \
  --name=metricbeat \
  --user=root \
  --volume="$(pwd)/metricbeat.docker.yml:/usr/share/metricbeat/metricbeat.yml:ro" \
  --volume="/sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro" \
  --volume="/proc:/hostfs/proc:ro" \
  --volume="/:/hostfs:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  docker.elastic.co/beats/metricbeat:7.0.0-SNAPSHOT \
  -e -strict.perms=false \
  -E cloud.id=$ELASTIC_CLOUD_ID \
  -E cloud.auth=$ELASTIC_CLOUD_CREDENTIALS


