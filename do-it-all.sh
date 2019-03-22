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

echo "Do you wish to remove any existing containers named elasticsearch, kibana, metricbeat, filebeat, heartbeat, and nginx?"
select ynq in "Yes" "No" "Quit"; do
    case $ynq in
        Yes ) docker rm -f elasticsearch;docker rm -f kibana;docker rm -f heartbeat; docker rm -f metricbeat; docker rm -f filebeat; docker rm -f nginx; break;;
        No ) echo "Continuing ..."; break;;
        Quit ) exit;;
    esac
done

# Note that I am adding labels for hint based Beats autodiscover, if you
# run Filebeat and Metricbeat and configure them for hints based autodiscover
# then the Elasticsearch and Kibana logs and metrics will be automatically
# discovered and processed with their respective modules.  This is a dev/demo
# configuration of Elasticsearch, see the docs for a production Docker run
# command

echo "Deploying Elasticsearch\n"

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
  docker.elastic.co/elasticsearch/elasticsearch:6.6.2

./healthstate.sh elasticsearch

# This starts Kibana.  Do not run this until Elasticsearch is healthy (docker ps)

echo "Deploying Kibana\n"
docker run -d \
  --name=kibana \
  --user=kibana \
  --network=course_stack -p 5601:5601 \
  --health-cmd='curl -s -f http://localhost:5601/login' \
  --label co.elastic.logs/module=kibana \
  --label co.elastic.metrics/module=kibana \
  --label co.elastic.metrics/hosts='${data.host}:${data.port}' \
  docker.elastic.co/kibana/kibana:6.6.2

./healthstate.sh kibana

# This is the setup command for Heartbeat.  It loads configs into Elasticsearch
# and Kibana.  Do not run this until Kibana is healthy (docker ps)

echo "Deploying Heartbeat\n"
docker run \
  --network=course_stack \
  docker.elastic.co/beats/heartbeat:6.6.2 \
  setup -E setup.kibana.host=kibana:5601 \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]

# This grabs a sample config for Heartbeat.
#curl -L -O https://raw.githubusercontent.com/elastic/beats/7.0/deploy/docker/heartbeat.docker.yml

docker run -d \
  --name=heartbeat \
  --user=heartbeat \
  --network=course_stack \
  --volume="$(pwd)/heartbeat.docker.yml:/usr/share/heartbeat/heartbeat.yml:ro" \
  docker.elastic.co/beats/heartbeat:6.6.2 \
  --strict.perms=false -e \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]

echo "Deploying Metricbeat\n"
docker run \
  --network=course_stack \
  docker.elastic.co/beats/metricbeat:6.6.2 \
  setup -E setup.kibana.host=kibana:5601 \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]

curl -L -O https://raw.githubusercontent.com/elastic/beats/master/deploy/docker/metricbeat.docker.yml


docker run -d \
  --name=metricbeat \
  --network=course_stack \
  --user=root \
  --volume="$(pwd)/metricbeat.docker.yml:/usr/share/metricbeat/metricbeat.yml:ro" \
  --volume="/sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro" \
  --volume="/proc:/hostfs/proc:ro" \
  --volume="/:/hostfs:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  docker.elastic.co/beats/metricbeat:6.6.2 \
  -e -strict.perms=false \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]



echo "Deploying Filbeat\n"

docker run \
  --network=course_stack \
  docker.elastic.co/beats/filebeat:6.6.2 \
  setup -E setup.kibana.host=kibana:5601 \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]

curl -L -O https://raw.githubusercontent.com/elastic/beats/6.6/deploy/docker/filebeat.docker.yml

docker run -d \
  --name=filebeat \
  --network=course_stack \
  --user=root \
  --volume="$(pwd)/filebeat.docker.yml:/usr/share/filebeat/filebeat.yml:ro" \
  --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  docker.elastic.co/beats/filebeat:6.6.2 \
  -e -strict.perms=false \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]

wget https://raw.githubusercontent.com/elastic/katacoda-scenarios/master/managing-docker/assets/nginx.conf
wget https://raw.githubusercontent.com/elastic/katacoda-scenarios/master/managing-docker/assets/nginx-default.conf

echo "Deploying NGINX, Apache, and Redis\n"
docker run -d \
  --net course_stack \
  --label co.elastic.logs/module=nginx \
  --label co.elastic.logs/fileset.stdout=access \
  --label co.elastic.logs/fileset.stderr=error \
  --label co.elastic.metrics/module=nginx \
  --label co.elastic.metrics/hosts='${data.host}:${data.port}' \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v $(pwd)/nginx-default.conf:/etc/nginx/conf.d/default.conf:ro \
  --name nginx \
  -p 8080:8080 nginx:1.15.4

wget https://raw.githubusercontent.com/elastic/katacoda-scenarios/master/managing-docker/assets/apache-mod-status.conf

wget https://raw.githubusercontent.com/elastic/katacoda-scenarios/master/managing-docker/assets/apache2.conf

wget https://raw.githubusercontent.com/elastic/katacoda-scenarios/master/managing-docker/assets/remoteip.load

docker run --name=redis-master \
  --label co.elastic.logs/module=redis \
  --label co.elastic.logs/fileset.stdout=log \
  --label co.elastic.metrics/module=redis \
  --label co.elastic.metrics/metricsets="info, keyspace" \
  --label co.elastic.metrics/hosts='${data.host}:${data.port}' \
  --env="GET_HOSTS_FROM=dns" \
  --env="HOME=/root" \
  --volume="/data" \
  --network=course_stack \
  --label com.docker.compose.service="redis-master" \
  --detach=true \
  gcr.io/google_containers/redis:e2e redis-server /etc/redis/redis.conf

docker run --name=redis-slave \
  --label co.elastic.logs/module=redis \
  --label co.elastic.logs/fileset.stdout=log \
  --label co.elastic.metrics/module=redis \
  --label co.elastic.metrics/metricsets="info, keyspace" \
  --label co.elastic.metrics/hosts='${data.host}:${data.port}' \
  --env="GET_HOSTS_FROM=dns" \
  --volume="/data" \
  --network=course_stack \
  --label com.docker.compose.service="redis-slave" \
  --detach=true \
  gcr.io/google_samples/gb-redisslave:v1 /bin/sh -c /run.sh

docker run \
  --name=frontend \
  --label co.elastic.logs/module=apache2 \
  --label co.elastic.logs/fileset.stdout=access \
  --label co.elastic.logs/fileset.stderr=error \
  --label co.elastic.metrics/module=apache \
  --label co.elastic.metrics/metricsets=status \
  --label co.elastic.metrics/hosts='${data.host}:${data.port}' \
  -v $(pwd)/apache2.conf:/etc/apache2/apache2.conf:ro \
  -v $(pwd)/apache-mod-status.conf:/etc/apache2/mods-available/status.conf:ro \
  -v $(pwd)/remoteip.load:/etc/apache2/mods-enabled/remoteip.load:ro \
  --env="GET_HOSTS_FROM=dns" \
  --network=course_stack \
  --label com.docker.compose.service="frontend" \
  --detach=true \
  gcr.io/google-samples/gb-frontend:v4 apache2-foreground


echo "Open a browser to http://localhost:5601/"

echo "generate traffic at http://localhost:8080/"
