#!/bin/bash

# 1103  curl -H 'Content-Type: application/json' http://127.0.0.1:$(docker ps | grep elastic | grep -Eo '0.0.0.0:[0-9]+' | cut -d: -f2)/"users/_search?pretty" -d'{ "query": { "query_string": { "query": "full_name:roman AND full_name:romeranian" } } }'
# 1104  curl http://127.0.0.1:$(docker ps | grep elastic | grep -Eo '0.0.0.0:[0-9]+' | cut -d: -f2)/"users/_mapping?pretty"
#
#
#curl -H 'Content-Type: application/json' http://127.0.0.1:$(docker ps | grep elastic | grep -Eo '0.0.0.0:[0-9]+' |
#  cut -d: -f2)/"users/_search?pretty" -d'
#  { "query" :
#    {"bool":{"should":[{"term":{"cuid":{"boost":100,"value":"Searchy Queryville MY","case_insensitive":true}}},{"term":{"email.keyword":{"boost":100,"value":"Searchy Queryville MY","case_insensitive":true}}},{"term":{"phoneNumber.keyword":{"boost":100,"value":"Searchy Queryville MY","case_insensitive":true}}},{"prefix":{"cuid":{"boost":80,"value":"Searchy Queryville MY","case_insensitive":true}}},{"prefix":{"email.keyword":{"boost":80,"value":"Searchy Queryville MY","case_insensitive":true}}},{"combined_fields":{"boost":80,"fields":["firstName","lastName"],"query":"Searchy Queryville MY","operator":"and"}},{"bool":{"minimum_should_match":"2","should":[{"match":{"firstName":{"boost":50,"query":"Searchy Queryville MY"}}},{"match":{"lastName":{"boost":50,"query":"Searchy Queryville MY"}}},{"match":{"state":{"boost":50,"query":"Searchy Queryville MY"}}},{"match":{"city":{"boost":50,"query":"Searchy Queryville MY"}}}]}},{"multi_match":{"boost":50,"fields":["fullName","email","phoneNumber"],"operator":"and","query":"Searchy Queryville MY","type":"best_fields"}},{"multi_match":{"boost":0.699999988079071,"fields":["fullName","email","phoneNumber"],"fuzziness":"AUTO","operator":"and","query":"Searchy Queryville MY","type":"best_fields"}}]}}
#  }
#'


