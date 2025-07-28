# Replicate an LDES into Virtuoso

In this example we show how to replicate and materialize the (mirrored) [Marine Regions](https://marineregions.org) LDES (<http://193.190.127.143:8080/marine-regions-mirror/ldes>) into a [(open source) Virtuoso](https://vos.openlinksw.com/owiki/wiki/VOS) instance. We show how to execute both the `ldes2sparql` pipeline and Virtuoso using Docker.

## Start up Virtuoso

We rely on the official [Virtuoso Docker image](https://hub.docker.com/r/openlink/virtuoso-opensource-7/). 

Make sure to provide enough memory resources via the [`NumberOfBuffers`](https://github.com/rdf-connect/ldes2sparql/blob/main/examples/virtuoso/virtuoso.ini#L95) and [`MaxDirtyBuffers`](https://github.com/rdf-connect/ldes2sparql/blob/main/examples/virtuoso/virtuoso.ini#L96) properties in the [`virtuoso.ini`](https://github.com/rdf-connect/ldes2sparql/blob/main/examples/virtuoso/virtuoso.ini) configuration file. The performance of SPARQL UPDATE queries largely depends on the given memory.


Run the following commands to spin up a Virtuoso instance:

```bash
docker pull openlink/virtuoso-opensource-7
docker run --name virtuoso --env DBA_PASSWORD=YOUR_PWD -p 1111:1111 -p 8890:8890 -v `pwd`:/database -it openlink/virtuoso-opensource-7:latest
```

### Enable SPARQL UPDATE on Virtuoso

By default SPARQL UDPATE queries are not allowed in Virtuoso. To enable them, follow these steps:

**⚠️Warning⚠️**: For this example, we allow full unrestricted SPARQL UPDATE permission over all named graphs. However, for production deployments, proper security and access control configurations should be made. See [the documentation](https://docs.openlinksw.com/virtuoso/rdfsparqlprotocolendpoint/#rdfsupportedprotocolendpointurisparqlauthex) for Virtuoso.

1. Login with your `dba` credential on `http://localhost:8890/conductor`.

2. Navigate to `Database` > `Interactive SQL`.

3. Execute the following command to authorize update operations for all named graphs:

   ```SQL
    DB.DBA.RDF_DEFAULT_USER_PERMS_SET ('nobody', 7);
   ```

4. Navigate to `System Admin` > `User Accounts` > `Users` and edit the `SPARQL` user. Add the `SPARQ_UPDATE` account role and click on save.

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
docker run --env-file conf.env ldes2sparql
```