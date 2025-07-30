# Replicate an LDES into Oxigraph

In this example we show how to replicate and materialize the (mirrored) [Marine Regions](https://marineregions.org) LDES (<http://193.190.127.143:8080/marine-regions-mirror/ldes>) into an [Oxigraph](https://github.com/oxigraph/oxigraph) instance. We show how to execute both the `ldes2sparql` pipeline and Oxigraph using Docker.

## Start up Oxigraph

We rely on the official [Oxigraph Docker image](ghcr.io/oxigraph/oxigraph). Run the following commands to spin up an Oxigraph instance:

1. Pull the latest Oxigraph Docker image:
```bash
docker pull ghcr.io/oxigraph/oxigraph:latest
```
2. Start up an Oxigraph instance:
```bash
docker run -v `pwd`:/data -p 7878:7878 ghcr.io/oxigraph/oxigraph serve --location /data --bind 0.0.0.0:7878
```

## Execute ldes2sparql

To start the replication and materialization process, run the `ldes2sparql` pipeline followin the next steps:

1. Download the `ldes2sparql` Docker image:
```bash
docker pull ghcr.io/rdf-connect/ldes2sparql:latest
```
2. Provide an environment configuration file. For example a `conf.env` file with this content:
```dotenv
### Pipeline logging level
LOG_LEVEL=info

### LDES client variables
LDES=http://193.190.127.143:8080/marine-regions-mirror/ldes
MATERIALIZE=true

### SPARQL ingest variables
SPARQL_ENDPOINT=http://{YOUR_LOCAL_IP}:7878/update
TARGET_GRAPH=https://www.marineregions.org/graph # For Oxigraph a named graph is optional
MAX_QUERY_LENGTH=10000 # A high number as it optimizes write performance
```
3. Execute the pipeline with the following Docker command:
```bash
docker run --env-file conf.env ghcr.io/rdf-connect/ldes2sparql
```