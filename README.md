# ldes2sparql

[RDF-Connect](https://rdf-connect.github.io/) pipeline for materializing [Linked Data Event Streams (LDES)](https://w3id.org/ldes/specification) into a target SPARQL graph store.

Internally, it uses the Typescript [ldes-client](https://github.com/rdf-connect/ldes-client) and the also Typescript [sparql-ingest-processor](https://github.com/rdf-connect/sparql-ingest-processor-ts) library.  

## Run with docker

Pull the docker image:
```bash
docker pull ghcr.io/rdf-connect/ldes2sparql:latest
```

Run a container instance with the following command:

```bash
docker run \
-e "LDES=http://your.ldes.address" \
-e "SPARQL_ENDPOINT=http://your.sparql.server/update" \
-e "TARGET_GRAPH=https://www.marineregions.org/graph" (optional)\
-e "ORDER=[ascending|descending]" (optional)\
-e "FOLLOW=[true|false]" (optional)\
-e "POLLING_FREQUENCY=5000" (optional)\
-e "MATERIALIZE=[true|false]" (optional)\
-e "LAST_VERSION_ONLY=[true|false]" (optional)\
-e "AFTER=2024-12-31T23:59:59.999Z" (optional)\
-e "BEFORE=2026-01-01T00:00:00.000Z" (optional)\
-e "SHAPE=https://my.dereferenceable.shape" (optional)\
-e "MAX_QUERY_LENGTH=500" (optional)\
-e "ACCESS_TOKEN=marine-regions_1234" (optional)\
-v /your/state/folder:/state \
ghcr.io/rdf-connect/ldes2sparql:latest
```

The container can also be run using an environment config file as follows:

```bash
docker run --env-file conf.env -v /your/state/folder:/state ghcr.io/rdf-connect/ldes2sparql:latest
```

A descritpion of all available environment variables is presented next:

- **`LDES`**: The URL of the LDES to be replicated and followed.
- **`SPARQL_ENDPOINT`**: The URL of the target SPARQL graph store, which must support the [SPARQL UPDATE specification](https://www.w3.org/TR/sparql11-update/).
- **`TARGET_GRAPH`** (optional): An IRI of a targeted named graph where all replicated triples will be written.
- **`ORDER`** (optional): An instruction for the LDES client to emit members in `ascending` or `descending` temporal order (based on the `ldes:timestampPath` property value).
- **`FOLLOW`** (optional): A property that indicates whether the LDES client should continue to poll the LDES for new events after the replication has been completed. The default value is `false`.
- **`POLLING_FREQUENCY`** (optional): A property that instructs the client to poll the LDES following the given frequency to check for new events after replication. It is given in milliseconds and it is ignored if `FOLLOW` is set to `false`. 
- **`MATERIALIZE`** (optional): Property that instructs the LDES client to materialize replicated members (i.e., to use the declared `ldes:versionOfPath` property value as the member subject). The default value is `false`.
- **`LAST_VERSION_ONLY`** (optional): Property that instructs the client to only emit the latest versions of every member. If enabled, it enforces the LDES client to emit members in an `descending` temporal order. The default value is `false`.
- **`AFTER`** (optional): Datetime property that instructs the client to only emit memebers timestamped after (exclusive) the given datetime. 
- **`BEFORE`** (optional): Datetime property that instructs the client to only emit memebers timestamped before (exclusive) the given datetime.
- **`SHAPE`** (optional): URL of a SHACL shape that the LDES client will use to guide the member extraction process to, for example, emit members with property subsets or include out-of-band (i.e., externally linked) property values. Alternatively, a local shape file may be used, but this requires a rebuilt of the Docker image of `ldes2sparql` that includes such shape file.
- **`CONCURRENT_FETCHES`** (optional): Maximum number of concurrent HTTP requests that the LDES client may perform while replicating the LDES. For some LDES, this needs to be limited to avoid, for example, `HTTP 429 Too many requests` responses. 
- **`MAX_QUERY_LENGHT`** (optional): Property that indicates the maximum number of triples allowed in INSERT DATA SPARQL queries, before splitting the query into multiple ones. This is useful to workaround hard query length limits, as [is the one for Virtuoso](https://github.com/openlink/virtuoso-opensource/blob/develop/7/libsrc/Wi/sparql2sql.h#L1031).
- **`ACCESS_TOKEN`** (optional): Security property that is required to [enable SPARQL UPDATE queries in Qlever](https://github.com/ad-freiburg/qlever/blob/41864b6cc95e167e098ee7466af37ccc8a925723/src/engine/Server.cpp#L497).


## Benchmarks

TODO