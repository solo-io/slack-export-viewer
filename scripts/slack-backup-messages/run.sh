#!/bin/bash

set -x 

./run-public.sh
./run-corp.sh
./combine-backups.sh