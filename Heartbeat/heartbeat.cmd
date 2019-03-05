#!/bin/sh

###
# These commands are not necessarily meant to be run
# as a script, I run them one at a time by copying and
# pasting.  You could add checks in after starting
# Elasticsearch and also after starting Kibana to make
# sure that things are started up before continuing.
# See https://github.com/elastic/katacoda-scenarios/blob/master/managing-docker/assets/healthstate.sh
# if you want to do this. (I added this in)
###

# There are multiple ways of setting up networking between Docker containers.
# At the time of writing, creating a shared network is the preferred method.

docker network create course_stack

# Note that I am adding labels for hint based Beats autodiscover, if you
# run Filebeat and Metricbeat and configure them for hints based autodiscover
# then the Elasticsearch and Kibana logs and metrics will be automatically
# discovered and processed with their respective modules.  This is a dev/demo
# configuration of Elasticsearch, see the docs for a production Docker run
# command

docker run -d \
  --name=elasticsearch \
  --label co.elastic.logs/module=elasticsearch \
  --label co.elastic.metrics/module=elasticsearch \
  --label co.elastic.metrics/hosts='${data.host}:9200' \
  --env="discovery.type=single-node" \
  --env="ES_JAVA_OPTS=-Xms256m -Xmx256m" \
  --network=course_stack \
  -p 9300:9300 -p 9200:9200 \
  --health-cmd='curl -s -f http://localhost:9200/_cat/health' \
  docker.elastic.co/elasticsearch/elasticsearch:7.0.0-beta1

./healthstate.sh elasticsearch

# This starts Kibana.  Do not run this until Elasticsearch is healthy (docker ps)

docker run -d \
  --name=kibana \
  --user=kibana \
  --network=course_stack -p 5601:5601 \
  --health-cmd='curl -s -f http://localhost:5601/login' \
  --label co.elastic.logs/module=kibana \
  --label co.elastic.metrics/module=kibana \
  --label co.elastic.metrics/hosts='${data.host}:${data.port}' \
  docker.elastic.co/kibana/kibana:7.0.0-beta1

./healthstate.sh kibana

# This is the setup command for Heartbeat.  It loads configs into Elasticsearch
# and Kibana.  Do not run this until Kibana is healthy (docker ps)

docker run \
  --network=course_stack \
  docker.elastic.co/beats/heartbeat:7.0.0-beta1 \
  setup -E setup.kibana.host=kibana:5601 \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]

# This grabs a sample config for Heartbeat.
curl -L -O https://raw.githubusercontent.com/elastic/beats/6.6/deploy/docker/heartbeat.docker.yml

docker run -d \
  --name=heartbeat \
  --user=heartbeat \
  --network=course_stack \
  --volume="$(pwd)/heartbeat.docker.yml:/usr/share/heartbeat/heartbeat.yml:ro" \
  docker.elastic.co/beats/heartbeat:7.0.0-beta1 \
  --strict.perms=false -e \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]
