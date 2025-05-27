# ldes2sparql

Connector Architecture pipeline for materializing an LDES into a SPARQL graph store.

## Run with docker

Run a container instance with the following command:

```bash
docker run \
-e "LDES=http://your.ldes.address" \
-e "ORDER=[ascending|descending]" \
-e "SPARQL_ENDPOINT=http://your.sparql.server" \
-e "TARGET_GRAPH=https://www.marineregions.org/graph" \
ldes2sparql
```
