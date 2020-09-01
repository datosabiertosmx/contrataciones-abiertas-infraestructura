#!/bin/bash

json_dir=$1
echo "Looking for JSON files -> " $json_dir

for f in $json_dir*
do
    echo 'Importing -> ' $f
    node import_to_edca.js $f
done
