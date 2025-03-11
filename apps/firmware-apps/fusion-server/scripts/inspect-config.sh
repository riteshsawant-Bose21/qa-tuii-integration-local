#!/bin/bash

# Script used to inspect the config.db database used by fusion-server
set -e

if [ $# -lt 2 ]; then
    cat <<EOF
Usage: $0 <instance-name> <bbolt command> [<args>...]

This script makes a temporary copy of the Bolt database located at
/var/lib/fusion/config.db on the specified multipass instance and then
runs the bbolt command against that copy.

The expected usage of the command is:

  $0 <instance> info <dbfile>
  $0 <instance> dump <dbfile>
  $0 <instance> stats <dbfile>
  $0 <instance> buckets <dbfile>
  $0 <instance> keys <dbfile> <bucket>
  $0 <instance> get <dbfile> <bucket> <key>
  $0 <instance> set <dbfile> <bucket> <key> <value>
  $0 <instance> delete <dbfile> <bucket> <key>

Examples:
  # Show database info:
  $0 fusion1 info

  # List all buckets:
  $0 fusion1 buckets

  # List keys in the "state" bucket:
  $0 fusion1 keys state

  # Retrieve the value for "mykey" in the "state" bucket:
  $0 fusion1 get state mykey | jq

  # Filter on a specific JSON key in the database
  $0 fusion1 get state latest | jq '.state.user_setting.data'`
EOF
    exit 1
fi

instance="$1"
shift

# Use multipass to run the following script as root inside the instance.
multipass exec "$instance" -- sudo bash -s -- "$@" <<'EOF'
set -e

# Create a temporary file for the DB copy.
TMP_DB=$(mktemp /tmp/config-copy.XXXXXX.db)

# Copy the live database to the temporary file.
cp /var/lib/fusion/config.db "$TMP_DB"

# Determine the bbolt subcommand and reorder arguments as needed.
cmd="$1"
shift

case "$cmd" in
    keys|get|set|delete)
        # For these commands the database file should be the first argument.
        # For example:
        #   bbolt get <dbfile> <bucket> <key>
        bbolt "$cmd" "$TMP_DB" "$@"
        ;;
    *)
        # For other commands the database file goes at the end.
        # For example:
        #   bbolt info <dbfile>
        bbolt "$cmd" "$@" "$TMP_DB"
        ;;
esac

# Clean up the temporary file.
rm -f "$TMP_DB"
EOF
