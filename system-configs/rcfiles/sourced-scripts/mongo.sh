CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/common.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/common.sh"
fi
CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function dns-lookup-srv-record() {
  dig "_mongodb._tcp.${1}" SRV +short
}

function shard-collections-instructions() {
  if [[ $# -lt 3 ]]; then
    echo 'Usage: shard-collections-instructions <COLLECTION> <ShardKey> <DATABASE>'
    return 1
  fi
  local COLLECTION=$1
  local SHARD_KEY=$2
  local DB=$3

  echo "Connect to DATABASE: ${DB}"

  echo "---COMMANDS---"
  cat <<EOM
// Verify Collection isn't Sharded:
use ${DB}
db.${COLLECTION}.getShardDistribution()

// Check Shard Key if it's sharded
use config
// VERBOSE
db.collections.find(
    { _id: "${DB}.${COLLECTION}" }
).pretty()

// CONCISE
db.collections.find(
    { _id: "${DB}.${COLLECTION}" },
    { key: 1 }
).pretty()

// Otherwise Shard the Collection
use ${DB}
sh.shardCollection("${DB}.${COLLECTION}", { $SHARD_KEY: 1 })
// Check to verify collection is sharded
db.${COLLECTION}.getShardDistribution()
EOM

}

function mongo-script-for-checking-inprog-ops() {
  echo 'db.currentOp(true).inprog'
}

function mongo-script-for-checking-index-build-progress() {
  echo 'db.currentOp(true).inprog.forEach(function(op){ if(op.msg!==undefined) print(op.shard, op.msg) })'
}

function mongo-script-for-ops-waiting-for-lock() {
  #shellcheck disable=SC2016
  echo 'db.currentOp(
      {
        "waitingForLock" : true,
        $or: [
            { "op" : { "$in" : [ "insert", "update", "remove" ] } },
            { "command.findandmodify": { $exists: true } }
        ]
      }
    )'
}

function mongo-script-for-ops-with-no-yields() {
  echo 'db.currentOp(
    {
      "active" : true,
      "numYields" : 0,
      "waitingForLock" : false
    }
  )'
}

function mongo-script-for-all-index-operations() {
  #shellcheck disable=SC2016
  echo 'db.adminCommand(
      {
        currentOp: true,
        $or: [
          { op: "command", "command.createIndexes": { $exists: true }  },
          { op: "command", "command.$truncated": /^\{ createIndexes/  },
          { op: "none", "msg" : /^Index Build/ }
        ]
      }
  )'
}

function mongo-jq-filter-query-log() {
  jq '
    .command as $command | .operation as $operation | .originatingCommand as $originatingCommand | .originatingCommand."$client" as $client | { $client, ns, planSummary, keysExamined, docsExamined, nreturned, numYields, queryHash, $command, $operation, $originatingCommand }
    | del (.client.env, .client.os)
    | del (.command."$audit", .command."$client", .command."$clusterTime", .command."$configTime", .command."$db", .command."$topologyTime", .command.clientOperationKey, .command.shardVersion, .command.databaseVersion, .command.lsid)
    | del (.operation."$audit", .operation."$client", .operation."$clusterTime", .operation."$configTime", .operation."$db", .operation."$topologyTime", .operation.clientOperationKey, .operation.shardVersion, .operation.databaseVersion, .operation.lsid)
    | del (.originatingCommand."$audit", .originatingCommand."$client", .originatingCommand."$clusterTime", .originatingCommand."$configTime", .originatingCommand."$db", .originatingCommand."$topologyTime", .originatingCommand.clientoriginatingCommandKey, .originatingCommand.shardVersion, .originatingCommand.databaseVersion, .originatingCommand.lsid)
  '
}

function mongo-example-find-shardkey() {
  if [[ $# -lt 2 ]]; then
    echo 'Usage: mongo-example-find-shardKey <COLLECTION> <DATABASE>'
    return 1
  fi
  local COLLECTION=$1
  local DB=$2

  # shellcheck disable=SC2005
  echo "$(cat <<EOM
db.getSiblingDB("config").collections.findOne({ _id: "${DB}.${COLLECTION}"})'
EOM
)"

}

function ffmongo() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

