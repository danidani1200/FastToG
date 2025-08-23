#!/bin/bash
# Script to set up and run FastToG with a Farsi Wikidata neo4j database.
# It installs dependencies, downloads the Farsi KG and Graph2Text model,
# launches a neo4j docker container, and runs an example query.

set -e

# ----------- Configuration -----------
# Directory to store downloaded resources
DATA_DIR="data"
MODEL_DIR="models"

# Neo4j credentials
NEO4J_USER="neo4j"
NEO4J_PASSWORD="test"
NEO4J_CONTAINER="neo4j-farsi"
NEO4J_PORT_HTTP=7474
NEO4J_PORT_BOLT=7687

# Property name storing Farsi labels in the neo4j database
KG_LABEL_PROPERTY="label"  # change to the actual property name if different

# Example query in Farsi
QUERY="آب و هوای منطقه‌ای که مرکز همایش‌های پنسیلوانیا در آن قرار دارد چیست؟"
ENTITY="مرکز همایش های پنسیلوانیا"
LLM_API="https://your-llm-endpoint"
LLM_API_KEY="your_api_key"

# -------------------------------------

mkdir -p "$DATA_DIR" "$MODEL_DIR"

# 1. Create virtual environment and install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install neo4j numpy pandas tqdm matplotlib igraph networkx torch httpx tiktoken requests gdown

# 2. Download Graph2Text model and Farsi Wikidata neo4j dump
#    Users may replace the following file IDs with mirrors if needed.
if [ ! -d "$MODEL_DIR/graph2text" ]; then
    gdown 1812Hy9eMHa_h7dQn70N6eQAmKR_x7WDH -O "$MODEL_DIR/graph2text.zip"
    unzip "$MODEL_DIR/graph2text.zip" -d "$MODEL_DIR/graph2text"
fi
if [ ! -d "$DATA_DIR/wikidata_db" ]; then
    gdown 1Vrdt86zqG2M1apaSAUciuqXx9BwQKd1g -O "$DATA_DIR/wikidata_neo4j.zip"
    unzip "$DATA_DIR/wikidata_neo4j.zip" -d "$DATA_DIR/wikidata_db"
fi

# 3. Launch neo4j docker container with the downloaded database
if ! docker ps -a --format '{{.Names}}' | grep -q "^$NEO4J_CONTAINER$"; then
    docker run -d --name "$NEO4J_CONTAINER" \
        -p ${NEO4J_PORT_HTTP}:7474 -p ${NEO4J_PORT_BOLT}:7687 \
        -e NEO4J_AUTH=${NEO4J_USER}/${NEO4J_PASSWORD} \
        -v "$(pwd)/$DATA_DIR/wikidata_db":/data \
        neo4j:5.15
else
    docker start "$NEO4J_CONTAINER"
fi

# 4. Wait for neo4j to start
sleep 20

# 5. Run FastToG with the Farsi KG
python fasttog.py \
    --query "$QUERY" \
    --entity "$ENTITY" \
    --base_path output \
    --llm_api "$LLM_API" \
    --llm_api_key "$LLM_API_KEY" \
    --graph2text_path "$MODEL_DIR/graph2text" \
    --kg_api bolt://localhost:${NEO4J_PORT_BOLT} \
    --kg_user "$NEO4J_USER" \
    --kg_pw "$NEO4J_PASSWORD" \
    --kg_label_property "$KG_LABEL_PROPERTY" \
    --kg_graph_file_name visulize \
    --community_max_size 4

