# Replicate an LDES into qEndpoint

In this example we show how to replicate and materialize the (mirrored) [Marine Regions](https://marineregions.org) LDES (<http://193.190.127.143:8080/marine-regions-mirror/ldes>) into a [qEndpoint](https://github.com/the-qa-company/qEndpoint) instance. We show how to execute both the `ldes2sparql` pipeline and qEndpoint using Docker.

## Start up qEndpoint

We rely on the official [qEndpoint Docker image](https://hub.docker.com/r/qacompany/qendpoint). Run the following commands to spin up a qEndpoing instance:

1. Pull the latest Docker image:
```bash
docker pull qacompany/qendpoint:latest
```
2. Start up a qEndpoint instance:
```bash
docker run -p 1234:1234 --name qendpoint --env MEM_SIZE=8G qacompany/qendpoint
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
SPARQL_ENDPOINT=http://{YOUR_LOCAL_IP}:1234/api/endpoint/sparql
TARGET_GRAPH=
MAX_QUERY_LENGTH=10000 # A high number as it optimizes write performance
```
We use an empty named graph (`TARGET_GRAPH=`) given that at the time of writing, [named graphs were not working properly in qEndpoint](https://github.com/the-qa-company/qEndpoint/issues/616).

3. Execute the pipeline with the following Docker command:
```bash
docker run --env-file conf.env ghcr.io/rdf-connect/ldes2sparql
```