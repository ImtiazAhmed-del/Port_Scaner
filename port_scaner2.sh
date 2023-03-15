#!/bin/bash

function scan_port {
    host=$1
    port=$2
    timeout 1 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && echo "Port $port: Open"
}

function scan_range {
    host=$1
    start_port=$2
    end_port=$3
    for ((port=start_port; port<=end_port; port++)); do
        scan_port $host $port
    done
}

function get_risk_level {
    port=$1
    case $port in
        21|22|23|25|80|443|3389)
            echo "High"
            ;;
        139|445|1433|1521)
            echo "Medium"
            ;;
        *)
            echo "Low"
            ;;
    esac
}

while getopts ":p:r:h" opt; do
    case $opt in
        p)
            port=$OPTARG
            ;;
        r)
            range=(${OPTARG//:/ })
            start_port=${range[0]}
            end_port=${range[1]}
            ;;
        h)
            echo "Usage: $0 [-p PORT] [-r START_PORT:END_PORT] host"
            exit 1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo "Usage: $0 [-p PORT] [-r START_PORT:END_PORT] host"
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            echo "Usage: $0 [-p PORT] [-r START_PORT:END_PORT] host"
            exit 1
            ;;
    esac
done

shift $((OPTIND -1))

host=$1

if [ -z "$host" ]; then
    echo "Error: Host argument missing."
    echo "Usage: $0 [-p PORT] [-r START_PORT:END_PORT] host"
    exit 1
fi

if [ -z "$port" ] && [ -z "$range" ]; then
    echo "Error: Either -p or -r must be specified."
    echo "Usage: $0 [-p PORT] [-r START_PORT:END_PORT] host"
    exit 1
fi

if [ -n "$port" ]; then
    scan_port $host $port
    risk_level=$(get_risk_level $port)
    echo "Risk level: $risk_level"
fi

if [ -n "$range" ]; then
    scan_range $host $start_port $end_port
    for ((port=start_port; port<=end_port; port++)); do
        timeout 1 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && echo "Port $port: Open" && risk_level=$(get_risk_level $port) && echo "Risk level: $risk_level"
    done
fi
