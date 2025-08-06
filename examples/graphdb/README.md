# Replicate an LDES into GraphDB

In this example we show how to replicate and materialize the (mirrored) [Marine Regions](https://marineregions.org) LDES (<http://193.190.127.143:8080/marine-regions-mirror/ldes>) into a [GraphDB](https://graphdb.ontotext.com/documentation/11.0/) instance. We show how to execute both the `ldes2sparql` pipeline and GraphDB using Docker.

## Start up GraphDB

We rely on the [official Docker image of GraphDB](https://hub.docker.com/r/ontotext/graphdb).

Starting v11, GraphDB requires a license key, even for their free version. This license can be requested on [their website](https://www.ontotext.com/products/graphdb/). Once a license has been obtained, follow these steps to spin up a GraphDB instance:

1. Pull the lastest image (at the time of writing this was v11.0.2):
```bash
docker pull ontotext/graphdb:11.0.2
```
2. Place the license file in the `conf` folder and rename it to `graphdb.license`.
```bash
cp <YOUR_LICENSE.license> conf && mv <YOUR_LICENSE.license> graphdb.license
```
3. Start GraphDB's Docker container:
```bash
docker run -p 7200:7200 -v `pwd`:/opt/graphdb/home --name graphdb -it -e GDB_HEAP_SIZE=8192m ontotext/graphdb:11.0.2
```
4. Create a GraphDB repository, which is mandatory to store data. We use the provided [`repo-config.ttl`](https://github.com/rdf-connect/ldes2sparql/blob/main/examples/graphdb/repo-config.ttl) file to configure it ([see the docs](https://graphdb.ontotext.com/documentation/11.0/configuring-a-repository.html#configuration-parameters) for more information on configuration parameters). Execute the repository creation using the GraphDB REST API:
```bash
curl http://localhost:7200/rest/repositories -H "Content-Type: multipart/form-data" -F "config=@repo-config.ttl"
```
The creation can be confirmed using the following request:
```bash
curl http://localhost:7200/rest/repositories -H "Accept: application/json"
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
SPARQL_ENDPOINT=http://{YOUR_LOCAL_IP}:7200/repositories/mr-repo/statements
TARGET_GRAPH=https://www.marineregions.org/graph # For GraphDB a named graph is optional
MAX_QUERY_LENGTH=10000 # A high number as it optimizes write performance
```
The path name `/mr-repo/` in the `SPARQL_ENDPOINT` parameter corresponds to the `rep:repositoryID` property defined in the repository config in `repo-config.ttl`.
3. Execute the pipeline with the following Docker command:
```bash
docker run --env-file conf.env ghcr.io/rdf-connect/ldes2sparql
```