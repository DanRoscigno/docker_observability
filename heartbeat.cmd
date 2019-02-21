
docker network create course_stack


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
  docker.elastic.co/elasticsearch/elasticsearch:6.7.0-SNAPSHOT

docker run -d \
  --name=kibana \
  --user=kibana \
  --network=course_stack -p 5601:5601 \
  --health-cmd='curl -s -f http://localhost:5601/login' \
  --label co.elastic.logs/module=kibana \
  --label co.elastic.metrics/module=kibana \
  --label co.elastic.metrics/hosts='${data.host}:${data.port}' \
  docker.elastic.co/kibana/kibana:6.7.0-SNAPSHOT

docker run \
  --network=course_stack \
  docker.elastic.co/beats/heartbeat:6.7.0-SNAPSHOT \
  setup -E setup.kibana.host=kibana:5601 \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]

curl -L -O https://raw.githubusercontent.com/elastic/beats/6.6/deploy/docker/heartbeat.docker.yml

docker run -d \
  --name=heartbeat \
  --user=heartbeat \
  --network=course_stack \
  --volume="$(pwd)/heartbeat.docker.yml:/usr/share/heartbeat/heartbeat.yml:ro" \
  docker.elastic.co/beats/heartbeat:6.7.0-SNAPSHOT \
  --strict.perms=false -e \
  -E output.elasticsearch.hosts=["elasticsearch:9200"]

