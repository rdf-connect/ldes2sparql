#!/bin/sh

# Replace any environment variable in the pipeline file
envs=`printenv`

for env in $envs
do
    echo "$env" | { 
        IFS='=' read name value;
        sed -i "s|\${${name}}|${value}|g" ./rdfc-pipeline.ttl;
    }
done


# Execute the RDF-Connect pipeline with the JS-Runner
exec npx @rdfc/js-runner rdfc-pipeline.ttl