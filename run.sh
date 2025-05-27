#!/bin/bash

# Replace environment variables
sed -i "s;\${LDES};$LDES;g;" rdfc-pipeline.ttl
sed -i "s;\${ORDER};$ORDER;g;" rdfc-pipeline.ttl
sed -i "s;\${SPARQL_ENDPOINT};$SPARQL_ENDPOINT;g;" rdfc-pipeline.ttl
sed -i "s;\${TARGET_GRAPH};$TARGET_GRAPH;g;" rdfc-pipeline.ttl

cat rdfc-pipeline.ttl

# Execute the RDF-Connect pipeline with the JS-Runner
exec npx @rdfc/js-runner rdfc-pipeline.ttl