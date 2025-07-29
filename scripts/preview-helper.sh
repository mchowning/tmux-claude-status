#!/usr/bin/env bash

input="$1"

# Check if this is a category separator line
if echo "$input" | grep -q "━━━"; then
    echo -e "\033[1;36mSelect a session below to see its preview\033[0m"
    exit 0
fi

# Check if this is the Ctrl-R reminder line
if echo "$input" | grep -q "Hit Ctrl-R "; then
    echo -e "\033[1;33mPress Ctrl-R to refresh the session list\033[0m"
    exit 0
fi

# Skip empty lines
if [ -z "$input" ] || [ "$input" = " " ]; then
    exit 0
fi

# Extract session name from the formatted line
session=$(echo "$input" | awk '{print $1}')

# Capture pane content with colors and escape sequences
if [ -n "$session" ]; then
    tmux capture-pane -ep -t "$session" 2>/dev/null || echo "No preview available"
else
    echo "No session selected"
fi
