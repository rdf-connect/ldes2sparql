#!/bin/bash

set -e

# Install the hyperfine benchmarking tool (Ubuntu)
if ! command -v hyperfine &> /dev/null; then
    wget https://github.com/sharkdp/hyperfine/releases/download/v1.19.0/hyperfine_1.19.0_amd64.deb
    sudo dpkg -i hyperfine_1.19.0_amd64.deb
    rm hyperfine_1.19.0_amd64.deb
fi

# Pull the ldes2sparql image
sudo docker pull ghcr.io/rdf-connect/ldes2sparql:latest

# Get the local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')
# Java memory settings
JAVA_HEAP=8192m

#########################################
###   Benchmark Apache Jena Fuseki    ###
#########################################
echo "Benchmarking Apache Jena Fuseki..."

if [ ! -d "fuseki" ]; then
    mkdir fuseki
    chmod 777 fuseki
fi
cd fuseki
# Build Jena Fuseki Docker image
sudo docker build --force-rm --network=host --build-arg JENA_VERSION=5.5.0 -t fuseki ../../examples/fuseki
# Run the Fuseki server
sudo docker run --rm -d -it -p 3030:3030 -v `pwd`:/fuseki/databases --name fuseki \
    -e JAVA_OPTIONS="-Xmx$JAVA_HEAP -Xms$JAVA_HEAP" fuseki --tdb2 --update --loc databases /marine-regions
echo "Waiting for Fuseki to start..."
sleep 10


FUSEKI_URL="http://$LOCAL_IP:3030/marine-regions/update"

# Run ldes2sparql (using hyperfine) to replicate the mirrored Marine Regions LDES into Fuseki
hyperfine --runs 5 --export-markdown ../results/fuseki.md \
    --prepare "curl \"${FUSEKI_URL}\" --data-urlencode \"update=DELETE { ?s ?p ?o } WHERE { ?s ?p ?o }\""\
    "sudo docker run --rm \
        -e LDES=http://193.190.127.143:8080/marine-regions-mirror/ldes \
        -e MATERIALIZE=true \
        -e SPARQL_ENDPOINT=${FUSEKI_URL} \
        -e AFTER=0000-01-01T00:00:00.000Z \
        -e SHAPE= -e TARGET_GRAPH= \
        -e PERF_NAME=fuseki \
        -v `pwd`/../results:/performance \
        ghcr.io/rdf-connect/ldes2sparql"

# Stop the Fuseki and clean up
sudo docker stop fuseki
cd ..
sudo rm -rf fuseki

#########################################
###       Benchmark GraphDB           ###
#########################################
echo "Benchmarking GraphDB..."

if [ ! -d "graphdb" ]; then
    mkdir graphdb
    chmod 777 graphdb
fi
cd graphdb
# Build GraphDB Docker image
if [ ! -d "conf" ]; then
    mkdir conf
    chmod 777 conf
fi

# Check if the license file exists
cp ../../examples/graphdb/conf/graphdb.license conf/
if [ ! -f conf/graphdb.license ]; then
    echo "GraphDB license file not found. Please place your GraphDB license in the examples/graphdb/conf directory."
else
    # Pull and run the GraphDB Docker image
    sudo docker pull ontotext/graphdb:11.0.2
    sudo docker run -d --rm -p 7200:7200 -v `pwd`:/opt/graphdb/home --name graphdb -it \
        -e GDB_HEAP_SIZE=$JAVA_HEAP ontotext/graphdb:11.0.2
    echo "Waiting for GraphDB to start..."
    sleep 10
    # Create the Marine Regions repository
    cp ../../examples/graphdb/repo-config.ttl .
    curl http://localhost:7200/rest/repositories -H "Content-Type: multipart/form-data" -F "config=@repo-config.ttl"
fi

GRAPHDB_URL="http://$LOCAL_IP:7200/repositories/mr-repo/statements"

# Run ldes2sparql (using hyperfine) to replicate the mirrored Marine Regions LDES into GraphDB
hyperfine --runs 5 --export-markdown ../results/graphdb.md \
    --prepare "curl \"${GRAPHDB_URL}\" --data-urlencode \"update=DELETE { ?s ?p ?o } WHERE { ?s ?p ?o }\""\
    "sudo docker run --rm \
        -e LDES=http://193.190.127.143:8080/marine-regions-mirror/ldes \
        -e MATERIALIZE=true \
        -e SPARQL_ENDPOINT=${GRAPHDB_URL} \
        -e AFTER=0000-01-01T00:00:00.000Z \
        -e SHAPE= -e TARGET_GRAPH= \
        -e PERF_NAME=graphdb \
        -v `pwd`/../results:/performance \
        ghcr.io/rdf-connect/ldes2sparql"

# Stop the GraphDB and clean up
sudo docker stop graphdb
cd ..
sudo rm -rf graphdb

#########################################
###       Benchmark Oxigraph          ###
#########################################
echo "Benchmarking Oxigraph..."

if [ ! -d "oxigraph" ]; then
    mkdir oxigraph
    chmod 777 oxigraph
fi
cd oxigraph

# Pull and run the Oxigraph Docker image
sudo docker pull ghcr.io/oxigraph/oxigraph:latest
sudo docker run --rm -d -v `pwd`:/data -p 7878:7878 --name oxigraph \
    ghcr.io/oxigraph/oxigraph serve --location /data --bind 0.0.0.0:7878
echo "Waiting for Oxigraph to start..."
sleep 10

OXIGRAPH_URL="http://$LOCAL_IP:7878/update"

# Run ldes2sparql (using hyperfine) to replicate the mirrored Marine Regions LDES into Oxigraph
hyperfine --runs 5 --export-markdown ../results/oxigraph.md \
    --prepare "curl \"${OXIGRAPH_URL}\" --data-urlencode \"update=DELETE { ?s ?p ?o } WHERE { ?s ?p ?o }\""\
    "sudo docker run --rm \
        -e LDES=http://193.190.127.143:8080/marine-regions-mirror/ldes \
        -e MATERIALIZE=true \
        -e SPARQL_ENDPOINT=${OXIGRAPH_URL} \
        -e AFTER=0000-01-01T00:00:00.000Z \
        -e SHAPE= -e TARGET_GRAPH= \
        -e PERF_NAME=oxigraph \
        -v `pwd`/../results:/performance \
        ghcr.io/rdf-connect/ldes2sparql"

# Stop the Oxigraph and clean up
sudo docker stop oxigraph
cd ..
sudo rm -rf oxigraph

#########################################
###       Benchmark qEndpoint         ###
#########################################
echo "Benchmarking qEndpoint..."

if [ ! -d "qendpoint" ]; then
    mkdir qendpoint
    chmod 777 qendpoint
fi
cd qendpoint

# Pull and run the qEndpoint Docker image
sudo docker pull qacompany/qendpoint:latest
sudo docker run --rm -d -p 1234:1234 --name qendpoint --env MEM_SIZE=8G qacompany/qendpoint
echo "Waiting for qEndpoint to start..."
sleep 10

QENDPOINT_URL="http://$LOCAL_IP:1234/api/endpoint/sparql"

# Run ldes2sparql (using hyperfine) to replicate the mirrored Marine Regions LDES into qEndpoint
hyperfine --runs 5 --export-markdown ../results/qendpoint.md \
    --prepare "curl \"${QENDPOINT_URL}\" --data-urlencode \"update=DELETE { ?s ?p ?o } WHERE { ?s ?p ?o }\""\
    "sudo docker run --rm \
        -e LDES=http://193.190.127.143:8080/marine-regions-mirror/ldes \
        -e MATERIALIZE=true \
        -e SPARQL_ENDPOINT=${QENDPOINT_URL} \
        -e AFTER=0000-01-01T00:00:00.000Z \
        -e SHAPE= -e TARGET_GRAPH= \
        -e PERF_NAME=qendpoint \
        -v `pwd`/../results:/performance \
        ghcr.io/rdf-connect/ldes2sparql"

# Stop the qEndpoint and clean up
sudo docker stop qendpoint
cd ..
sudo rm -rf qendpoint

#########################################
###          Benchmark Qlever         ###
#########################################
echo "Benchmarking Qlever..."

if [ ! -d "qlever" ]; then
    mkdir qlever
    chmod 777 qlever
fi
cd qlever

# Pull the Qlever Docker image
sudo docker pull adfreiburg/qlever:latest
# Build an index structure for Qlever
cp ../../examples/qlever/marine-regions.settings.json .
sudo docker run -u $(id -u):$(id -g) --rm -v /etc/localtime:/etc/localtime:ro \
    -v $(pwd):/index -w /index --init --entrypoint bash --name qlever adfreiburg/qlever \
    -c "IndexBuilderMain -i marine-regions -s marine-regions.settings.json -F ttl -f - --stxxl-memory 10G"
# Run the Qlever server
sudo docker run -d -u $(id -u):$(id -g) --rm -v /etc/localtime:/etc/localtime:ro -v $(pwd):/index -p 7000:7000 \
    -w /index --init --entrypoint bash --name qlever adfreiburg/qlever \
    -c 'ServerMain -i marine-regions -j 4 -p 7000 -m 8G -c 4G -e 4G -k 200 -s 30s -a marine-regions_1234'
echo "Waiting for Qlever to start..."
sleep 10

QLEVER_URL="http://$LOCAL_IP:7000"

# Run ldes2sparql (using hyperfine) to replicate the mirrored Marine Regions LDES into Qlever
hyperfine --runs 5 --export-markdown ../results/qlever.md \
    --prepare "curl \"${QLEVER_URL}\" --data-urlencode \"update=DELETE { ?s ?p ?o } WHERE { ?s ?p ?o }\""\
    "sudo docker run --rm \
        -e ACCESS_TOKEN=marine-regions_1234 \
        -e LDES=http://193.190.127.143:8080/marine-regions-mirror/ldes \
        -e MATERIALIZE=true \
        -e SPARQL_ENDPOINT=${QLEVER_URL} \
        -e AFTER=0000-01-01T00:00:00.000Z \
        -e SHAPE= -e TARGET_GRAPH= \
        -e PERF_NAME=qlever \
        -v `pwd`/../results:/performance \
        ghcr.io/rdf-connect/ldes2sparql"

# Stop the Qlever and clean up
sudo docker stop qlever
cd ..
sudo rm -rf qlever

#########################################
###        Benchmark Virtuoso         ###
#########################################
echo "Benchmarking Virtuoso Open Source..."

if [ ! -d "virtuoso" ]; then
    mkdir virtuoso
    chmod 777 virtuoso
fi
cd virtuoso

# Pull the Virtuoso Docker image
sudo docker pull openlink/virtuoso-opensource-7:latest
# Prepare start up commands to enable SPARQL UPDATE queries
mkdir initdb.d
chmod 777 initdb.d
cp ../../examples/virtuoso/initdb.d/* initdb.d/
# Run the Virtuoso server
sudo docker run -d --rm --name virtuoso --env DBA_PASSWORD=dba -p 1111:1111 -p 8890:8890 \
    -v `pwd`:/database -v `pwd`/initdb.d:/initdb.d -it \
    -e VIRT_PARAMETERS_NumberOfBuffers=2720000 -e VIRT_PARAMETERS_MaxDirtyBuffers=2000000 \
    -e VIRT_SPARQL_ResultSetMaxRows=10000000 -e VIRT_SPARQL_MaxConstructTriples=10000000 \
    -e VIRT_SPARQL_MaxQueryExecutionTime=0 -e VIRT_SPARQL_MaxQueryCostEstimationTime=0 \
    openlink/virtuoso-opensource-7:latest
# Run the Virtuoso server
echo "Waiting for Virtuoso to start..."
sleep 45

VIRTUOSO_URL="http://$LOCAL_IP:8890/sparql"

# Run ldes2sparql (using hyperfine) to replicate the mirrored Marine Regions LDES into VIRTUOSO
hyperfine --runs 5 --export-markdown ../results/virtuoso.md \
    --prepare "curl \"${VIRTUOSO_URL}\" --data-urlencode \"update=WITH <https://www.marineregions.org/graph> DELETE { ?s ?p ?o } WHERE { ?s ?p ?o }\""\
    "sudo docker run --rm \
        -e LDES=http://193.190.127.143:8080/marine-regions-mirror/ldes \
        -e MATERIALIZE=true \
        -e SPARQL_ENDPOINT=${VIRTUOSO_URL} \
        -e TARGET_GRAPH=https://www.marineregions.org/graph \
        -e FOR_VIRTUOSO=true \
        -e AFTER=0000-01-01T00:00:00.000Z \
        -e SHAPE= \
        -e PERF_NAME=virtuoso \
        -v `pwd`/../results:/performance \
        ghcr.io/rdf-connect/ldes2sparql"

# Stop the Virtuoso and clean up
sudo docker stop virtuoso
cd ..
sudo rm -rf virtuoso