# Replicate an LDES into Virtuoso

In this example we show how to replicate and materialize the (mirrored) [Marine Regions](https://marineregions.org) LDES (<http://193.190.127.143:8080/marine-regions-mirror/ldes>) into a [(open source) Virtuoso](https://vos.openlinksw.com/owiki/wiki/VOS) instance. We show how to execute both the `ldes2sparql` pipeline and Virtuoso using Docker.

## Start up Virtuoso

We rely on the official [Virtuoso Docker image](https://hub.docker.com/r/openlink/virtuoso-opensource-7/). 

Run the following commands to spin up a Virtuoso instance:

1. Pull the latest Virtuoso image:
```bash
docker pull openlink/virtuoso-opensource-7:latest
```
2. Start up a Virtuoso instance. Adjust the `VIRT_PARAMETERS_NumberOfBuffers` and `VIRT_PARAMETERS_MaxDirtyBuffer` environment variables to set the amount of memory Virtuoso is allowed to use:
```bash
docker run --name virtuoso --env DBA_PASSWORD=YOUR_PWD -p 1111:1111 -p 8890:8890 -v `pwd`:/database -v `pwd`/initdb.d:/initdb.d -it -e VIRT_PARAMETERS_NumberOfBuffers=2720000 -e VIRT_PARAMETERS_MaxDirtyBuffers=2000000 openlink/virtuoso-opensource-7:latest
```
SPARQL UPDATE queries are disallowed by default in Virtuoso, but we enable them with the [`initdb.d/enable_update.sql`](https://github.com/rdf-connect/ldes2sparql/blob/main/examples/virtuoso/initdb.d/enable_update.sql) script. This script grants update permissions to the default `SPARQL` user and allows unrestricted access to all named graphs. 

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
SPARQL_ENDPOINT=http://{YOUR_LOCAL_IP}:8890/sparql
TARGET_GRAPH=https://www.marineregions.org/graph # For Virtuoso a named graph is mandatory
MAX_QUERY_LENGTH=500 # A low number to avoid Virtuoso hard query limits
```
3. Execute the pipeline with the following Docker command:
```bash
docker run --env-file conf.env ghcr.io/rdf-connect/ldes2sparql
```