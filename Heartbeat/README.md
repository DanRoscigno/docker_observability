## Requirements
1. Docker
1. Port 5601 open

## Setup
The script `heartbeat.sh` will deploy Elasticsearch 7.0.0-beta1, Kibana (same version), and Heartbeat in Docker containers.  Port 5601 is exposed for Kibana.  The script will 

1. Offer to remove existing containers named `elasticsearch`, `kibana`, and `heartbeat`.  
1. Create a Docker network
1. Deploy Elasticsearch
1. Deploy Kibana
1. Deploy Heartbeat

### Steps
`./heartbeat.sh`

Launch a browser to http://localhost:5601/

Set `heartbeat-*` as your default index pattern

View the Uptime app at http://localhost:5601/app/uptime

