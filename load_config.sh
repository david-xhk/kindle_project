#!/bin/bash

# Check if config has been loaded
if [ ${CONFIG_LOADED:-0} -eq 0 ]
then    
    # Load config file
    echo "Loading config file..."
    . ${1:-config}
    echo "Loaded config file"
    echo
    
    # Set CONFIG_LOADED flag
    export CONFIG_LOADED=1;
fi

# Do nothing if config has been loaded
