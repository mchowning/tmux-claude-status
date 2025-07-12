#!/usr/bin/env bash

input="$1"

# Check if this is a category separator line
if echo "$input" | grep -q "━━━"; then
    echo "Category separator"
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