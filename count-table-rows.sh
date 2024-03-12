#!/usr/bin/env bash

# count-table-rows.sh
# by Jon Jensen <jon@endpointdev.com>
# 2024-03-12
# This is free and unencumbered software released into the public domain. See Unlicense: https://unlicense.org/

set -euo pipefail
shopt -s expand_aliases
trap 'exit 1' INT

#export PGUSER=postgres
alias psql="psql -XqtA"
alias timestamp="date -u -Iseconds"

echo -n "Host: "
hostname -f

echo -n "Started at: "
timestamp
echo

odd_names=$(psql -c "
    SELECT quote_ident(datname)
    FROM pg_database
    WHERE datallowconn
        AND datname <> quote_ident(datname)
    ORDER BY 1
")
if [[ -n "$odd_names" ]]; then
    echo "Skipping these databases whose names cause trouble for the shell:"
    echo "$odd_names"
    echo
fi

psql -c "
    SELECT datname
    FROM pg_database
    WHERE datallowconn
        AND datname = quote_ident(datname)
    ORDER BY 1
" | while read db
do
    echo "Working on database $db"
    export PGDATABASE=$db

    psql -c "
        SELECT format('%I.%I', schemaname, tablename)
        FROM pg_tables
        WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
        ORDER BY schemaname, tablename
    " | while read table
    do
        echo -n "Rows in table $table = "
        psql -c "SELECT count(*) FROM $table"
    done
    echo
done

echo -n "Ended at: "
timestamp
