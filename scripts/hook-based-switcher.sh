#!/usr/bin/env bash

# Hook-based session switcher that reads status from files

STATUS_DIR="$HOME/.cache/tmux-claude-status"

# Function to check if Claude is in a session (actually running, not just has status file)
has_claude_in_session() {
    local session="$1"
    
    # Check all panes in the session for claude processes
    while IFS=: read -r pane_id pane_pid; do
        if pgrep -P "$pane_pid" -f "claude" >/dev/null 2>&1; then
            return 0  # Found Claude process
        fi
    done < <(tmux list-panes -t "$session" -F "#{pane_id}:#{pane_pid}" 2>/dev/null)
    
    return 1  # No Claude process found
}

# Function to get Claude status from hook files
get_claude_status() {
    local session="$1"
    local status_file="$STATUS_DIR/${session}.status"
    
    if [ -f "$status_file" ]; then
        # Read status from file (should be "working" or "done")
        cat "$status_file" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Get all sessions with formatted output
get_sessions_with_status() {
    local working_sessions=()
    local done_sessions=()
    local no_claude_sessions=()
    
    # Collect all sessions into arrays
    while IFS=: read -r name windows attached; do
        local formatted_line=""
        
        # First check if Claude is present
        if has_claude_in_session "$name"; then
            # Get status from hook file
            local claude_status=$(get_claude_status "$name")
            
            # Default to "done" if no status file exists
            [ -z "$claude_status" ] && claude_status="done"
            
            if [ "$claude_status" = "working" ]; then
                formatted_line=$(printf "%-20s %2s windows %-12s \033[33m[⚡ working]\033[0m" "$name" "$windows" "$attached")
                working_sessions+=("$formatted_line")
            else
                formatted_line=$(printf "%-20s %2s windows %-12s \033[32m[✓ done]\033[0m" "$name" "$windows" "$attached")
                done_sessions+=("$formatted_line")
            fi
        else
            formatted_line=$(printf "%-20s %2s windows %-12s" "$name" "$windows" "$attached")
            no_claude_sessions+=("$formatted_line")
        fi
    done < <(tmux list-sessions -F "#{session_name}:#{session_windows}:#{?session_attached,(attached),}")
    
    # Output grouped sessions with separators
    
    # Working sessions
    if [ ${#working_sessions[@]} -gt 0 ]; then
        echo -e "\033[1;33m━━━ ⚡ WORKING ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        printf '%s\n' "${working_sessions[@]}"
    fi
    
    # Done sessions
    if [ ${#done_sessions[@]} -gt 0 ]; then
        [ ${#working_sessions[@]} -gt 0 ] && echo
        echo -e "\033[1;32m━━━ ✓ DONE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        printf '%s\n' "${done_sessions[@]}"
    fi
    
    # No Claude sessions
    if [ ${#no_claude_sessions[@]} -gt 0 ]; then
        [ ${#working_sessions[@]} -gt 0 ] || [ ${#done_sessions[@]} -gt 0 ] && echo
        echo -e "\033[1;90m━━━ NO CLAUDE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        printf '%s\n' "${no_claude_sessions[@]}"
    fi
}

# Main
sessions=$(get_sessions_with_status)

# Use fzf to select with vim keybindings
selected=$(echo "$sessions" | fzf \
    --ansi \
    --no-sort \
    --header="Sessions grouped by Claude status | j/k: navigate | Enter: select | Esc: cancel" \
    --preview 'if echo {} | grep -q "━━━"; then echo "Category separator"; else session=$(echo {} | awk "{print \$1}"); tmux capture-pane -ep -t "$session" 2>/dev/null || echo "No preview available"; fi' \
    --preview-window=right:40%:wrap \
    --prompt="Session> " \
    --bind="j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up" \
    --layout=reverse \
    --info=inline)

# Switch to selected session (skip separator lines)
if [ -n "$selected" ] && ! echo "$selected" | grep -q "━━━"; then
    session_name=$(echo "$selected" | awk '{print $1}')
    tmux switch-client -t "$session_name"
fi