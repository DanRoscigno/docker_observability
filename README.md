Observability, what the heck is that?

Knowing everything about the application / service that you are providing so that you can answer the questions "How is your app doing?", "what is the user experience like?", "Why is xyz happening?", "Did you know that it was unresponsive last night at 9:15?", and of course "what was the root cause?"

The files here will get you a sample app and shippers (to collect the logs and metrics) running in a Docker env.  The code for the sample app has been instrumented to collect application performance metrics (APM) and support distributed tracing.  All of the data is shipped to an Elasticsearch Service on Elastic Cloud instance that you will deploy (use a trial account if you are not already a customer).  You can use a self managed deployment of the Elastic Stack if you like.

### Steps
### Deploy an Elasticsearch Service instance on Elastic Cloud
Make sure that you have APM enabled when you create the deployment

Make sure that you copy the `elastic` user password.  All of the other details can be retrieved later, but if you lose the `elastic` password you have to reset that password.

### Grab this repo
`git clone git@github.com:DanRoscigno/docker_observability.git`

`cd docker_observability/`

### Set your environment vars
The functionality depends on having a connection to the Elastic Stack.  Edit the file `environment` and set your specifics.  They will look something like this:
```
export ELASTIC_APM_SERVER_URL=https://xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apm.europe-west1.gcp.cloud.es.io:443

export ELASTIC_CLOUD_ID=xxx:xxxxxxxxxxxxxxxxxxxxxxx==

export ELASTIC_CLOUD_CREDENTIALS=elastic:xxxxxxxxxxxxxxxxxxxxxxxx

export ELASTIC_APM_SECRET_TOKEN=##################

# This one you don't have to edit
export ELASTIC_APM_TRACE_METHODS=co.elastic.apm.opbeans.*#*
```

### Source the environment vars
`source ./environment`

### Grab the source for the sample app
`git clone https://github.com/elastic/apm-integration-testing.git`

`cd apm-integration-testing`

### Start the app
`./scripts/compose.py start master --apm-server-url=$ELASTIC_APM_SERVER_URL --apm-server-secret-token=$ELASTIC_APM_SECRET_TOKEN --no-apm-server --no-elasticsearch --no-kibana --with-opbeans-node --with-opbeans-ruby --with-opbeans-go  --no-metricbeat --no-filebeat`

### Start collecting logs and metrics
After the downloads happen and things start running, then deploy Filebeat and Metricbeat
`cd ..`

`./metricbeat.sh`

`./filebeat.sh`

### Add in uptime / heartbeat here

### Have a look
Navigate to Kibana in your Elasticsearch Service instance

