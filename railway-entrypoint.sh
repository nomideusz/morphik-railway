#!/bin/sh
# Railway entrypoint for Morphik (API by default, worker when given a command).
# Replaces upstream's docker-entrypoint.sh, which waits for a host literally
# named "postgres" and exits after 60 s when there is none.
set -e
cd /app

: "${PORT:=8000}"
: "${MORPHIK_COMPLETION_MODEL:=gpt-4.1-mini}"
: "${MORPHIK_EMBEDDING_MODEL:=text-embedding-3-small}"
: "${MORPHIK_EMBEDDING_DIMENSIONS:=1536}"
: "${AWS_REGION:=auto}"
: "${MORPHIK_API_DOMAIN:=localhost:$PORT}"
export MORPHIK_API_DOMAIN PORT MORPHIK_COMPLETION_MODEL MORPHIK_EMBEDDING_MODEL MORPHIK_EMBEDDING_DIMENSIONS AWS_REGION

# Morphik only reads secrets from env; everything else comes from morphik.toml.
python -c 'import os; open("morphik.toml", "w").write(os.path.expandvars(open("morphik.toml.railway").read()))'

# Morphik's arq worker looks up the bucket for page images by this name.
export MULTIVECTOR_CHUNKS_BUCKET="${MULTIVECTOR_CHUNKS_BUCKET:-$S3_BUCKET}"

[ $# -gt 0 ] || set -- uvicorn core.api:app --host 0.0.0.0 --port "$PORT"
exec "$@"
