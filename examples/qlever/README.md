# Replicate an LDES into Qlever

In this example we show how to replicate and materialize the (mirrored) [Marine Regions](https://marineregions.org) LDES (<http://193.190.127.143:8080/marine-regions-mirror/ldes>) into a [Qlever](https://github.com/ad-freiburg/qlever) instance. We show how to execute both the `ldes2sparql` pipeline and Qlever using Docker.

## Start up Qlever

We rely on the official [Qlever Docker image](https://hub.docker.com/r/adfreiburg/qlever). Follow these steps to spin up an Qlever instance:

1. Pull the latest Qlever Docker image:
```bash
docker pull adfreiburg/qlever:latest
```
2. Build an index structure. Here Qlever requires a configuration file, for which we give an example with [marine-regions.settings.json](https://github.com/rdf-connect/ldes2sparql/blob/main/examples/qlever/marine-regions.settings.json):
```bash
docker run -u $(id -u):$(id -g) --rm -v /etc/localtime:/etc/localtime:ro -v $(pwd):/index -w /index --init --entrypoint bash --name qlever adfreiburg/qlever -c "IndexBuilderMain -i marine-regions -s marine-regions.settings.json -F ttl -f - --stxxl-memory 10G | tee qlever.index-log.txt"
```
3. Start the Qlever server with:
```bash
docker run -u $(id -u):$(id -g) --rm -v /etc/localtime:/etc/localtime:ro -v $(pwd):/index -p 7000:7000 -w /index --init --entrypoint bash --name qlever adfreiburg/qlever -c 'ServerMain -i marine-regions -j 4 -p 7000 -m 5G -c 2G -e 1G -k 200 -s 30s -a marine-regions_1234 > qlever-log.txt 2>&1'
```
**⚠️Warning⚠️**: For this example we enable updates by setting an access token `marine-regions_1234` with the `-a` parameter. This is mandatory for Qlever. However this should be a well protected secret in a real deployment. The list of configuration paramenters of Qlever's `ServerMain` CLI (as of 27/07/25) is the following:
```
Options for ServerMain:
  -h [ --help ]                         Produce this help message.
  -i [ --index-basename ] arg           The basename of the index files 
                                        (required).
  -p [ --port ] arg                     The port on which HTTP requests are 
                                        served (required).
  -a [ --access-token ] arg             Access token for restricted API calls 
                                        (default: no access).
  -j [ --num-simultaneous-queries ] arg (=1)
                                        The number of queries that can be 
                                        processed simultaneously.
  -m [ --memory-max-size ] arg (=4 GB)  Limit on the total amount of memory 
                                        that can be used for query processing 
                                        and caching. If exceeded, query will 
                                        return with an error, but the engine 
                                        will not crash.
  -c [ --cache-max-size ] arg (=30 GB)  Maximum memory size for all cache 
                                        entries (pinned and not pinned). Note 
                                        that the cache is part of the total 
                                        memory limited by --memory-max-size.
  -e [ --cache-max-size-single-entry ] arg (=5 GB)
                                        Maximum size for a single cache entry. 
                                        That is, results larger than this will 
                                        not be cached unless pinned.
  -E [ --cache-max-size-lazy-result ] arg (=5 MB)
                                        Maximum size up to which lazy results 
                                        will be cached by aggregating partial 
                                        results. Caching does cause significant
                                        overhead for this case.
  -k [ --cache-max-num-entries ] arg (=1000)
                                        Maximum number of entries in the cache.
                                        If exceeded, remove least-recently used
                                        non-pinned entries from the cache. Note
                                        that this condition and the size limit 
                                        specified via --cache-max-size both 
                                        have to hold (logical AND).
  -P [ --no-patterns ]                  Disable the use of patterns. If 
                                        disabled, the special predicate 
                                        `ql:has-predicate` is not available.
  -T [ --no-pattern-trick ]             Maximum number of entries in the cache.
                                        If exceeded, remove least-recently used
                                        entries from the cache if possible. 
                                        Note that this condition and the size 
                                        limit specified via --cache-max-size-gb
                                        both have to hold (logical AND).
  -t [ --text ]                         Also load the text index. The text 
                                        index must have been built before using
                                        `IndexBuilderMain` with options `-d` 
                                        and `-w`.
  -o [ --only-pso-and-pos-permutations ] 
                                        Only load the PSO and POS permutations.
                                        This disables queries with predicate 
                                        variables.
  -s [ --default-query-timeout ] arg (=30s)
                                        Set the default timeout in seconds 
                                        after which queries are 
                                        cancelledautomatically.
  -S [ --service-max-value-rows ] arg (=10000)
                                        The maximal number of result rows to be
                                        passed to a SERVICE operation as a 
                                        VALUES clause to optimize its 
                                        computation.
  --throw-on-unbound-variables arg (=0) If set to true, the queries that use 
                                        GROUP BY, BIND, or ORDER BY with 
                                        variables that are unbound in the query
                                        throw an exception. These queries 
                                        technically are allowed by the SPARQL 
                                        standard, but typically are the result 
                                        of typos and unintended by the user
  --request-body-limit arg (=100 MB)    Set the maximum size for the body of 
                                        requests the server will process. Set 
                                        to zero to disable the limit.
  --cache-service-results arg (=0)      SERVICE is not cached because we have 
                                        to assume that any remote endpoint 
                                        might change at any point in time. If 
                                        you control the endpoints, you can 
                                        override this setting. This will 
                                        disable the sibling optimization where 
                                        VALUES are dynamically pushed into 
                                        `SERVICE`.
  --persist-updates                     If set, then SPARQL UPDATES will be 
                                        persisted on disk. Otherwise they will 
                                        be lost when the engine is stopped
  --syntax-test-mode arg (=0)           Make several query patterns that are 
                                        syntactially valid, but otherwise 
                                        erroneous silently into empty results 
                                        (e.g. LOAD or SERVICE requests to 
                                        nonexisting endpoints). This mode 
                                        should only be used for running the 
                                        syntax tests from the W3C SPARQL 1.1 
                                        test suite.
  --enable-prefilter-on-index-scans arg (=1)
                                        If set to false, the prefilter 
                                        procedures for FILTER expressions are 
                                        disabled.
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
SPARQL_ENDPOINT=http://{YOUR_LOCAL_IP}:7000
TARGET_GRAPH=https://www.marineregions.org/graph # For Qlever a named graph is optional
MAX_QUERY_LENGTH=10000 # A high number as it optimizes write performance
ACCESS_TOKEN=marine-regions_1234
```
3. Execute the pipeline with the following Docker command:
```bash
docker run --env-file conf.env ghcr.io/rdf-connect/ldes2sparql
```