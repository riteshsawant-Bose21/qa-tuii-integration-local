#!/usr/bin/env bash

killall noise-generator

# Check if the number of generators is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <number_of_generators>"
    exit 1
fi

NUM_GENERATORS=$1

# Array of signal types
SIGNAL_TYPES=("white" "sin" "drum")

# Function to spawn a single noise generator
spawn_noise_generator() {
    local id=$1
    local channel=$id
    local random_type=${SIGNAL_TYPES[$RANDOM % ${#SIGNAL_TYPES[@]}]}
    
    echo "Spawning generator $id on channel $channel with type: $random_type"
    go run main.go -type "$random_type" -channel "$channel" 2>&1 | sed "s/^/[Generator $id] /"
}

# Spawn the specified number of noise generators
for ((i=1; i<=NUM_GENERATORS; i++)); do
    spawn_noise_generator $i &
done

echo "Spawned $NUM_GENERATORS noise generator(s)"

# Wait for all background processes to finish
wait
