# ldes2sparql

[RDF-Connect](https://rdf-connect.github.io/) pipeline for materializing [Linked Data Event Streams (LDES)](https://w3id.org/ldes/specification) into a target SPARQL graph store.

Internally, it uses the Typescript [ldes-client](https://github.com/rdf-connect/ldes-client) and the also Typescript [sparql-ingest-processor](https://github.com/rdf-connect/sparql-ingest-processor-ts).  

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
-e "FOR_VIRTUOSO=true" (optional)\
-e "ACCESS_TOKEN=marine-regions_1234" (optional)\
-e "PERF_NAME=virtuoso" (optional) \
-e "FAILURE_IS_FATAL[true|false]" (optional) \
-e "QUERY_TIMEOUT=30" (optional) \
-v /your/state/folder:/state \
-v /your/benchmark/folder:/performance \
ghcr.io/rdf-connect/ldes2sparql:latest
```

The container can also be run using an environment [config file](https://github.com/rdf-connect/ldes2sparql/blob/main/conf.env) as follows:

```bash
docker run --env-file conf.env -v /your/state/folder:/state ghcr.io/rdf-connect/ldes2sparql:latest
```

A descritpion of all available environment variables is presented next:performance

- **`LDES`**: The URL of the LDES to be replicated and followed.
- **`SPARQL_ENDPOINT`**: The URL of the target SPARQL graph store, which must support the [SPARQL UPDATE specification](https://www.w3.org/TR/sparql11-update/).
- **`TARGET_GRAPH`** (optional): An IRI of a targeted named graph where all replicated triples will be written. If not required, define it with an empty value (`TARGET_GRAPH=`), otherwise invalid queries will be produced.
- **`ORDER`** (optional): An instruction for the LDES client to emit members in `ascending` or `descending` temporal order (based on the `ldes:timestampPath` property value).
- **`FOLLOW`** (optional): A property that indicates whether the LDES client should continue to poll the LDES for new events after the replication has been completed. The default value is `false`.
- **`POLLING_FREQUENCY`** (optional): A property that instructs the client to poll the LDES following the given frequency to check for new events after replication. It is given in milliseconds and it is igperformancenored if `FOLLOW` is set to `false`. 
- **`MATERIALIZE`** (optional): Property that instructs the LDES client to materialize replicated members (i.e., to use the declared `ldes:versionOfPath` property value as the member subject). The default value is `false`.
- **`LAST_VERSION_ONLY`** (optional): Property that instructs the client to only emit the latest versions of every member. If enabled, it enforces the LDES client to emit members in an `descending` temporal order. The default value is `false`.
- **`AFTER`** (optional): Datetime property that instructs the client to only emit memebers timestamped after (exclusive) the given datetime. 
- **`BEFORE`** (optional): Datetime property that instructs the client to only emit memebers timestamped before (exclusive) the given datetime.
- **`SHAPE`** (optional): URL of a SHACL shape that the LDES client will use to guide the [member extraction process](https://github.com/TREEcg/extract-cbd-shape) to, for example, emit members with property subsets or include out-of-band (i.e., externally linked) property values. Alternatively, a local shape file may be used, but this requires the Docker image of `ldes2sparql` to be rebuilt including such shape file.
- **`CONCURRENT_FETCHES`** (optional): Maximum number of concurrent HTTP requests that the LDES client may perform while replicating the LDES. For some LDES, this needs to be limited to avoid, for example, `HTTP 429 Too many requests` responses. 
- **`FOR_VIRTUOSO`** (optional): Property to indicate that the target SPARQL graph store is a Virtuso instance, which then splits large INSERT DATA queries, to avoid Virtuoso's hard limits such as the [max SQL query length](https://github.com/openlink/virtuoso-opensource/blob/develop/7/libsrc/Wi/sparql2sql.h#L1031) and the [max query vector size](https://community.openlinksw.com/t/virtuosoexception-sq199/1950).
- **`ACCESS_TOKEN`** (optional): Security property that is required to [enable SPARQL UPDATE queries in Qlever](https://github.com/ad-freiburg/qlever/blob/41864b6cc95e167e098ee7466af37ccc8a925723/src/engine/Server.cpp#L497).
- **`PERF_NAME`** (optional): Name of the file that will be use to record the individual request times for benchmarking purposes.
- **`FAILURE_IS_FATAL`** (optional): Indicates whether the pipeline execution is fully stopped when a query does not succeed.
- **`QUERY_TIMEOUT`** (optional): Maximum time in seconds that is allowed for a query to be resolved. If the time is exceeded, an error will be thrown. If not specified, a default timeout of 30 mins will be set. 

## Benchmarks

We run some benchmarks using `ldes2sparql` to fully replicate the [Marine Regions (mirror) LDES](http://193.190.127.143:8080/marine-regions-mirror/ldes) into different open source SPARQL graph stores.

We measured the time that took `ldes2sparql` to fully replicate the LDES into the target SPARQL store and also the individual request times, having a `timeout of 30 seconds` per request. The benchmarks were run using Dockerized components (i.e., every graph store and the ldes2sparql pipeline run in their own Docker containers) in a server having: 
- `1x6 core Intel Core i5-9500 CPU (3.00GHz)`
- `64GB of RAM` (with 60GB allocated to the SPARQL engines) 
- `512GB Western Digital TM PC SN810 NVMeTM SSD`

For reproducibility we set datetime constraints to the LDES replication process, instructing the LDES client to replicate all members before `2025-08-14T00:00:00.000Z`, which results in a total of `64369 members`, that are then materialized (i.e., we end up with the latest version of every member) into a knowledge graph having `749862 triples` in total. The benchmarks were executed using the [`hyperfine`](https://github.com/sharkdp/hyperfine) tool.

**Table 1.** Total execution time for a full LDES replication.
| SPARQL engine | Total time [s] | Timeouts |
|:---|---:|---:|
| Apache Jena Fuseki | 5653.153 | 0 |
| GraphDB | 1080.582 | 0 |
| Oxigraph | 355.631 | 0 |
| Qendpoint | 20055.339 | 330 |
| Qlever | 302825.197 | 0 |
| Virtuoso | **334.591** | 0 |