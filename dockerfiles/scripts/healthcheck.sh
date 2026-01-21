#!/bin/bash
# healthcheck.sh

# 1. Check if the server is responding at all
if ! curl -s http://localhost:8000/health > /dev/null; then
  exit 1
fi

# 2. Check if the models list is populated
# This ensures the engine has finished loading weights into the GPU
MODELS_COUNT=$(curl -s http://localhost:8000/v1/models | jq '.data | length')

if [ "$MODELS_COUNT" -gt 0 ]; then
  exit 0
else
  exit 1
fi