#!/bin/bash

# Ensure LOG.log exists and is empty
#> LOG.log

# Continuously append lines to LOG.log
while true; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "ERROR Log entry at ${timestamp}" >> LOG.log
    sleep 1  # Adjust the sleep duration as needed
done
