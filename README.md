Observability, what the heck is that?

Knowing everything about the application / service that you are providing so that you can answer the questions "How is your app doing?", "what is the user experience like?", "Why is xyz happening?", "Did you know that it was unresponsive last night at 9:15?", and of course "what was the root cause?"

The files here will get you a sample app and shippers (to collect the logs and metrics) running in a Docker env.  The code for the sample app has been instrumented to collect application performance metrics (APM) and support distributed tracing.  All of the data is shipped to an Elasticsearch Service on Elastic Cloud instance that you will deploy (use a trial account if you are not already a customer).  You can use a self managed deployment of the Elastic Stack if you like.
