#!/bin/bash

# nvim-session.sh - Neovim session status functions
# Usage: source nvim-session.sh in your .bashrc
# Then use: session-nvim, session-nvim-clean, session-nvim-open

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Session directory (matches your Neovim config)
SESSIONS_DIR="$HOME/.local/share/nvim/sessions"

# Function to check if a PID is running
_nvim_session_is_process_running() {
    local pid=$1
    
    if [ -z "$pid" ] || ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        return 1  # Invalid PID
    fi
    
    if kill -0 "$pid" 2>/dev/null; then
        return 0  # Process is running
    else
        return 1  # Process is not running
    fi
}

# Function to convert session name back to path
_nvim_session_name_to_path() {
    local session_name=$1
    local path="${session_name//_//}"
    
    # Remove leading slash if present (from leading underscore)
    if [[ "$path" =~ ^/ ]]; then
        path="${path#/}"
    fi
    
    # Add leading slash
    path="/$path"
    
    # Replace home directory with ~
    if [[ "$path" == "$HOME"* ]]; then
        if [[ "$path" == "$HOME" ]]; then
            path="~"
        else
            path="~${path#$HOME}"
        fi
    fi
    
    echo "$path"
}

# Main function to list sessions
session-nvim() {
    echo -e "${BLUE}Neovim Session Status${NC}"
    echo "=========================="
    echo
    
    if [ ! -d "$SESSIONS_DIR" ]; then
        echo -e "${YELLOW}No sessions directory found at: $SESSIONS_DIR${NC}"
        return 1
    fi
    
    local session_count=0
    local active_count=0
    local stale_count=0
    local closed_count=0
    
    # Header
    printf "%-50s %-10s\n" "PATH" "STATUS"
    printf "%-50s %-10s\n" "----" "------"
    
    # Find all session directories
    for session_dir in "$SESSIONS_DIR"/*/; do
        if [ ! -d "$session_dir" ]; then
            continue
        fi
        
        session_count=$((session_count + 1))
        
        local session_name=$(basename "$session_dir")
        local session_path=$(_nvim_session_name_to_path "$session_name")
        local lock_file="$session_dir/.session.lock"
        
        local status="CLOSED"
        local status_color="$NC"
        
        # Check lock status
        if [ -f "$lock_file" ]; then
            local lock_content=$(cat "$lock_file" 2>/dev/null)
            local lock_pid=$(echo "$lock_content" | head -n1 | tr -d '[:space:]')
            
            if [ -n "$lock_pid" ] && _nvim_session_is_process_running "$lock_pid"; then
                status="ACTIVE"
                status_color="$GREEN"
                active_count=$((active_count + 1))
            else
                status="STALE"
                status_color="$YELLOW"
                stale_count=$((stale_count + 1))
            fi
        else
            closed_count=$((closed_count + 1))
        fi
        
        # Print session info
        printf "${status_color}%-50s %-10s${NC}\n" \
            "$session_path" \
            "$status"
    done
    
    if [ $session_count -eq 0 ]; then
        echo -e "${YELLOW}No sessions found${NC}"
        return
    fi
    
    echo
    echo "Summary:"
    echo -e "  ${GREEN}Active:${NC} $active_count   ${YELLOW}Stale:${NC} $stale_count   ${NC}Closed:${NC} $closed_count   ${BLUE}Total:${NC} $session_count"
    
    if [ $stale_count -gt 0 ]; then
        echo
        echo -e "${YELLOW}💡 Tip: Use 'session-nvim-clean' to remove stale locks${NC}"
    fi
}

# Function to clean stale locks
session-nvim-clean() {
    echo -e "${BLUE}Cleaning stale session locks...${NC}"
    
    if [ ! -d "$SESSIONS_DIR" ]; then
        echo -e "${YELLOW}No sessions directory found at: $SESSIONS_DIR${NC}"
        return 1
    fi
    
    local cleaned=0
    for session_dir in "$SESSIONS_DIR"/*/; do
        if [ ! -d "$session_dir" ]; then
            continue
        fi
        
        local lock_file="$session_dir/.session.lock"
        if [ -f "$lock_file" ]; then
            local lock_content=$(cat "$lock_file")
            local lock_pid=$(echo "$lock_content" | head -n1)
            
            if [ -n "$lock_pid" ] && ! _nvim_session_is_process_running "$lock_pid"; then
                local session_name=$(basename "$session_dir")
                local session_path=$(_nvim_session_name_to_path "$session_name")
                echo "  Removing stale lock for $session_path (PID $lock_pid)"
                rm "$lock_file"
                cleaned=$((cleaned + 1))
            fi
        fi
    done
    
    if [ $cleaned -eq 0 ]; then
        echo "  No stale locks found"
    else
        echo -e "${GREEN}  Cleaned $cleaned stale lock(s)${NC}"
    fi
}

# Function to open a session or any directory
session-nvim-open() {
    _session_nvim_open_impl "$@"
}

# Short alias function
so() {
    _session_nvim_open_impl "$@"
}

# Implementation function (DRY)
_session_nvim_open_impl() {
    local session_pattern="$1"
    
    if [ -z "$session_pattern" ]; then
        # No arguments provided, show all sessions for selection
        if [ ! -d "$SESSIONS_DIR" ]; then
            echo -e "${YELLOW}No sessions directory found at: $SESSIONS_DIR${NC}"
            return 1
        fi
        
        local all_sessions=()
        for session_dir in "$SESSIONS_DIR"/*/; do
            if [ ! -d "$session_dir" ]; then
                continue
            fi
            
            local session_name=$(basename "$session_dir")
            local session_path=$(_nvim_session_name_to_path "$session_name")
            all_sessions+=("$session_path")
        done
        
        if [ ${#all_sessions[@]} -eq 0 ]; then
            echo -e "${YELLOW}No sessions found${NC}"
            return 1
        fi
        
        echo -e "${BLUE}Available sessions:${NC}"
        local i=1
        for session_path in "${all_sessions[@]}"; do
            echo "  $i) $session_path"
            ((i++))
        done
        echo
        echo "Choose a session number (1-$((i-1))):"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
            local selected="${all_sessions[$((choice-1))]}"
            
            echo -e "${GREEN}Opening session: $selected${NC}"
            
            # Expand ~ to home directory for cd
            local actual_path="$selected"
            if [[ "$actual_path" == "~"* ]]; then
                actual_path="${actual_path/#\~/$HOME}"
            fi
            
            # Change to directory and open nvim
            cd "$actual_path" && nvim
        else
            echo -e "${RED}Invalid selection${NC}"
            return 1
        fi
        return 0
    fi
    
    # First, try to find matching sessions if sessions directory exists
    local matches=()
    if [ -d "$SESSIONS_DIR" ]; then
        for session_dir in "$SESSIONS_DIR"/*/; do
            if [ ! -d "$session_dir" ]; then
                continue
            fi
            
            local session_name=$(basename "$session_dir")
            local session_path=$(_nvim_session_name_to_path "$session_name")
            
            # Check if pattern matches anywhere in the session path
            if [[ "$session_path" == *"$session_pattern"* ]]; then
                matches+=("$session_path")
            fi
        done
    fi
    
    if [ ${#matches[@]} -eq 1 ]; then
        # Exact session match found
        local session_path="${matches[0]}"
        
        echo -e "${GREEN}Opening session: $session_path${NC}"
        
        # Expand ~ to home directory for cd
        local actual_path="$session_path"
        if [[ "$actual_path" == "~"* ]]; then
            actual_path="${actual_path/#\~/$HOME}"
        fi
        
        # Change to directory and open nvim
        cd "$actual_path" && nvim
        
    elif [ ${#matches[@]} -gt 1 ]; then
        # Multiple session matches found
        echo -e "${YELLOW}Multiple sessions found matching '$session_pattern':${NC}"
        local i=1
        for session_path in "${matches[@]}"; do
            echo "  $i) $session_path"
            ((i++))
        done
        echo
        echo "Please be more specific or choose a number (1-$((i-1))):"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
            local selected="${matches[$((choice-1))]}"
            
            echo -e "${GREEN}Opening session: $selected${NC}"
            
            # Expand ~ to home directory for cd
            local actual_path="$selected"
            if [[ "$actual_path" == "~"* ]]; then
                actual_path="${actual_path/#\~/$HOME}"
            fi
            
            # Change to directory and open nvim
            cd "$actual_path" && nvim
        else
            echo -e "${RED}Invalid selection${NC}"
            return 1
        fi
        
    else
        # No session matches found, treat as regular path
        local target_path="$session_pattern"
        
        # Expand ~ to home directory
        if [[ "$target_path" == "~"* ]]; then
            target_path="${target_path/#\~/$HOME}"
        fi
        
        # Convert to absolute path if relative
        if [[ "$target_path" != /* ]]; then
            target_path="$(pwd)/$target_path"
        fi
        
        # Check if the path exists
        if [ -d "$target_path" ]; then
            echo -e "${GREEN}Opening directory: $target_path${NC}"
            cd "$target_path" && nvim
        elif [ -f "$target_path" ]; then
            # If it's a file, open the file's directory and the file
            local dir_path=$(dirname "$target_path")
            local file_name=$(basename "$target_path")
            echo -e "${GREEN}Opening file: $target_path${NC}"
            cd "$dir_path" && nvim "$file_name"
        else
            echo -e "${RED}Path does not exist: $target_path${NC}"
            return 1
        fi
    fi
}

session-nvim-help() {
    echo "Neovim Session Management Functions:"
    echo "  session-nvim        - List all sessions with status"
    echo "  session-nvim-clean  - Remove stale session locks"
    echo "  session-nvim-open   - Open a session by path/pattern OR any directory"
    echo "  so                  - Short alias for session-nvim-open"
    echo "  session-nvim-help   - Show this help"
    echo
    echo "Session Status:"
    echo "  ACTIVE - Session currently open in Neovim"
    echo "  STALE  - Lock file exists but process is dead"
    echo "  CLOSED - No lock file, session is available"
    echo
    echo "Usage Examples:"
    echo "  # List all sessions for selection:"
    echo "  session-nvim-open"
    echo
    echo "  # Open existing session by pattern:"
    echo "  session-nvim-open frontend"
    echo "  session-nvim-open lits"
    echo
    echo "  # Open any directory (creates new session):"
    echo "  session-nvim-open ~/mojir/lits"
    echo "  session-nvim-open /Users/albert.mojir/projects/new-project"
    echo "  session-nvim-open ../some-project"
    echo
    echo "  # Open specific file:"
    echo "  session-nvim-open ~/mojir/lits/README.md"
    echo
    echo "Behavior:"
    echo "  1. First searches for existing sessions matching the pattern"
    echo "  2. If no sessions match, treats argument as a file/directory path"
    echo "  3. Changes to the directory and opens nvim"
}

# Helper function to get available sessions
_nvim_session_get_sessions() {
    if [ ! -d "$SESSIONS_DIR" ]; then
        return 0
    fi
    
    for session_dir in "$SESSIONS_DIR"/*/; do
        if [ ! -d "$session_dir" ]; then
            continue
        fi
        
        local session_name=$(basename "$session_dir")
        local session_path=$(_nvim_session_name_to_path "$session_name")
        echo "$session_path"
    done | sort -u
}

# Enhanced completion function for session-nvim-open with substring matching and directory support
_session_nvim_open_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local sessions
    local matches=()
    
    # Get existing sessions
    sessions=$(_nvim_session_get_sessions)
    
    # Add session matches (substring matching)
    while IFS= read -r session; do
        if [[ "$session" == *"$cur"* ]]; then
            matches+=("$session")
        fi
    done <<< "$sessions"
    
    # Add directory completion
    # Use compgen to get directory matches
    local dir_matches
    dir_matches=$(compgen -d -- "$cur" 2>/dev/null)
    
    # Add directory matches to our results
    while IFS= read -r dir; do
        if [ -n "$dir" ]; then
            matches+=("$dir")
        fi
    done <<< "$dir_matches"
    
    # Remove duplicates and sort
    local IFS=$'\n'
    matches=($(printf '%s\n' "${matches[@]}" | sort -u))
    
    # Set completion results
    COMPREPLY=("${matches[@]}")
}

# Register completion functions
complete -F _session_nvim_open_completion session-nvim-open
complete -F _session_nvim_open_completion so
