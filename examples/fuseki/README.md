# Replicate an LDES into Apache Jena Fuseki

In this example, we show how to replicate and materialize the (mirrored) [Marine Regions](https://marineregions.org) LDES (<http://193.190.127.143:8080/marine-regions-mirror/ldes>) into an [Apache Jena Fuseki](https://jena.apache.org/documentation/fuseki2/) instance. We show how to execute both the `ldes2sparql` pipeline and Fuseki using Docker.

## Start up Fuseki

Fuseki does not have an official Docker image in a public registry, but they do provide the [required files and instructions](https://github.com/apache/jena/tree/main/jena-fuseki2/jena-fuseki-docker) to build and run an instance using Docker. We provide such files in this repository. Run the following commands to spin up a Fuseki instance:

1. Build the Docker image. At the time of writing Jena's latest version was 5.5.0:
```bash
docker build --force-rm --build-arg JENA_VERSION=5.5.0 -t fuseki .
```
2. Start up a Fuseki instance. In this example, we opt for a persisted Fuseki on disk based on [TBD2](https://jena.apache.org/documentation/tdb2/) (`--tdb2`), we enable SPARQL UPDATE queries (`--update`) and increase the default memory limit of Java from 2GB to 8GB. Check the [Fuseki docs](https://jena.apache.org/documentation/fuseki2/fuseki-configuration.html) for a complete list of configuration parameters:  
```bash
docker run -it -p 3030:3030 -v `pwd`:/fuseki/databases --name fuseki -e JAVA_OPTIONS="-Xmx8192m -Xms8192m" fuseki --tdb2 --update --loc databases /marine-regions
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
SPARQL_ENDPOINT=http://{YOUR_LOCAL_IP}:3030/marine-regions/update
TARGET_GRAPH=https://www.marineregions.org/graph # For Fuseki a named graph is optional
MAX_QUERY_LENGTH=10000 # A high number as it optimizes write performance
```
3. Execute the pipeline with the following Docker command:
```bash
docker run --env-file conf.env ghcr.io/rdf-connect/ldes2sparql
```
