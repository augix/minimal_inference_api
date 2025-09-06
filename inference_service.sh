#!/bin/bash

# Inference Service Management Script
# This script manages inference service

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SCRIPT="$SCRIPT_DIR/inference_api.py"
WEB_UI_SCRIPT="$SCRIPT_DIR/web_ui.py"
API_PID_FILE="$SCRIPT_DIR/.api.pid"
WEB_UI_PID_FILE="$SCRIPT_DIR/.web_ui.pid"
API_LOG_FILE="$SCRIPT_DIR/api.log"
WEB_UI_LOG_FILE="$SCRIPT_DIR/web_ui.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to check if a process is running
is_running() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$pid_file"
            return 1
        fi
    fi
    return 1
}

# Function to start the API service
start_api() {
    if is_running "$API_PID_FILE"; then
        print_status $YELLOW "API service is already running (PID: $(cat $API_PID_FILE))"
        return 0
    fi
    
    print_status $BLUE "Starting API service..."
    cd "$SCRIPT_DIR"
    nohup python "$API_SCRIPT" > "$API_LOG_FILE" 2>&1 &
    local api_pid=$!
    echo $api_pid > "$API_PID_FILE"
    
    # Wait a moment to check if it started successfully
    sleep 2
    if is_running "$API_PID_FILE"; then
        print_status $GREEN "API service started successfully (PID: $api_pid)"
        print_status $BLUE "API logs: $API_LOG_FILE"
        return 0
    else
        print_status $RED "Failed to start API service. Check logs: $API_LOG_FILE"
        return 1
    fi
}

# Function to start the Web UI service
start_web_ui() {
    if is_running "$WEB_UI_PID_FILE"; then
        print_status $YELLOW "Web UI service is already running (PID: $(cat $WEB_UI_PID_FILE))"
        return 0
    fi
    
    print_status $BLUE "Starting Web UI service..."
    cd "$SCRIPT_DIR"
    nohup streamlit run "$WEB_UI_SCRIPT" --server.address 0.0.0.0 --server.port 8051 > "$WEB_UI_LOG_FILE" 2>&1 &
    local web_ui_pid=$!
    echo $web_ui_pid > "$WEB_UI_PID_FILE"
    
    # Wait a moment to check if it started successfully
    sleep 3
    if is_running "$WEB_UI_PID_FILE"; then
        print_status $GREEN "Web UI service started successfully (PID: $web_ui_pid)"
        print_status $BLUE "Web UI logs: $WEB_UI_LOG_FILE"
        return 0
    else
        print_status $RED "Failed to start Web UI service. Check logs: $WEB_UI_LOG_FILE"
        return 1
    fi
}

# Function to stop a service
stop_service() {
    local service_name=$1
    local pid_file=$2
    local log_file=$3
    
    if is_running "$pid_file"; then
        local pid=$(cat "$pid_file")
        print_status $BLUE "Stopping $service_name service (PID: $pid)..."
        kill "$pid"
        
        # Wait for graceful shutdown
        local count=0
        while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
            sleep 1
            count=$((count + 1))
        done
        
        if ps -p "$pid" > /dev/null 2>&1; then
            print_status $YELLOW "Graceful shutdown failed, forcing kill..."
            kill -9 "$pid"
            sleep 1
        fi
        
        rm -f "$pid_file"
        print_status $GREEN "$service_name service stopped"
    else
        print_status $YELLOW "$service_name service is not running"
    fi
}

# Function to check service status
check_status() {
    print_status $BLUE "Checking service status..."
    echo
    
    # Check API service
    if is_running "$API_PID_FILE"; then
        local api_pid=$(cat "$API_PID_FILE")
        print_status $GREEN "✓ API service is running (PID: $api_pid, Port: 8001)"
    else
        print_status $RED "✗ API service is not running"
    fi
    
    # Check Web UI service
    if is_running "$WEB_UI_PID_FILE"; then
        local web_ui_pid=$(cat "$WEB_UI_PID_FILE")
        print_status $GREEN "✓ Web UI service is running (PID: $web_ui_pid, Port: 8051)"
    else
        print_status $RED "✗ Web UI service is not running"
    fi
    
    echo
    print_status $BLUE "Service URLs:"
    print_status $BLUE "  API Health Check: http://localhost:8001/health"
    print_status $BLUE "  Web UI: http://localhost:8051"
}

# Function to show logs
show_logs() {
    local service=$1
    case $service in
        api)
            if [ -f "$API_LOG_FILE" ]; then
                print_status $BLUE "API Service Logs (last 50 lines):"
                tail -n 50 "$API_LOG_FILE"
            else
                print_status $YELLOW "No API logs found"
            fi
            ;;
        web)
            if [ -f "$WEB_UI_LOG_FILE" ]; then
                print_status $BLUE "Web UI Service Logs (last 50 lines):"
                tail -n 50 "$WEB_UI_LOG_FILE"
            else
                print_status $YELLOW "No Web UI logs found"
            fi
            ;;
        *)
            print_status $BLUE "API Service Logs (last 20 lines):"
            if [ -f "$API_LOG_FILE" ]; then
                tail -n 20 "$API_LOG_FILE"
            else
                print_status $YELLOW "No API logs found"
            fi
            echo
            print_status $BLUE "Web UI Service Logs (last 20 lines):"
            if [ -f "$WEB_UI_LOG_FILE" ]; then
                tail -n 20 "$WEB_UI_LOG_FILE"
            else
                print_status $YELLOW "No Web UI logs found"
            fi
            ;;
    esac
}

# Function to clean up old logs
clean_logs() {
    print_status $BLUE "Cleaning up old log files..."
    rm -f "$API_LOG_FILE" "$WEB_UI_LOG_FILE"
    print_status $GREEN "Log files cleaned"
}

# Main script logic
case "$1" in
    start)
        print_status $BLUE "Starting inference service..."
        start_api
        start_web_ui
        echo
        check_status
        ;;
    stop)
        print_status $BLUE "Stopping inference service..."
        stop_service "API" "$API_PID_FILE" "$API_LOG_FILE"
        stop_service "Web UI" "$WEB_UI_PID_FILE" "$WEB_UI_LOG_FILE"
        ;;
    restart)
        print_status $BLUE "Restarting inference service..."
        stop_service "API" "$API_PID_FILE" "$API_LOG_FILE"
        stop_service "Web UI" "$WEB_UI_PID_FILE" "$WEB_UI_LOG_FILE"
        sleep 2
        start_api
        start_web_ui
        echo
        check_status
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs "$2"
        ;;
    clean)
        clean_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|clean}"
        echo
        echo "Commands:"
        echo "  start   - Start both API and Web UI services"
        echo "  stop    - Stop both API and Web UI services"
        echo "  restart - Restart both services"
        echo "  status  - Show status of all services"
        echo "  logs    - Show logs (usage: $0 logs [api|web])"
        echo "  clean   - Clean up log files"
        echo
        echo "Service URLs:"
        echo "  API Health Check: http://localhost:8001/health"
        echo "  Web UI: http://localhost:8051"
        exit 1
        ;;
esac
