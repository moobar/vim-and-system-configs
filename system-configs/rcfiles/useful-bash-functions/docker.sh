#!/bin/bash

# 1103  curl -H 'Content-Type: application/json' http://127.0.0.1:$(docker ps | grep elastic | grep -Eo '0.0.0.0:[0-9]+' | cut -d: -f2)/"users/_search?pretty" -d'{ "query": { "query_string": { "query": "full_name:roman AND full_name:romeranian" } } }'
# 1104  curl http://127.0.0.1:$(docker ps | grep elastic | grep -Eo '0.0.0.0:[0-9]+' | cut -d: -f2)/"users/_mapping?pretty"

