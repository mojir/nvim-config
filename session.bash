#!/bin/bash

# nvim-session.sh - Neovim session status functions
# Usage: source nvim-session.sh in your .bashrc
# Then use: session-nvim [command] [args...]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Session directory (matches your Neovim config)
SESSIONS_DIR="$HOME/.local/share/nvim/sessions"

# Function to check if a PID is running
_session_nvim_is_process_running() {
    local pid=$1
    [ -n "$pid" ] && [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

# Function to convert session name back to path
_session_nvim_name_to_path() {
    local path="${1//_//}"
    [[ "$path" =~ ^/ ]] && path="${path#/}"
    path="/$path"
    if [[ "$path" == "$HOME"* ]]; then
        [ "$path" = "$HOME" ] && path="~" || path="~${path#$HOME}"
    fi
    echo "$path"
}

# Function to get lock status and info
_session_nvim_get_lock_status() {
    local session_dir="$1"
    local lock_file="$session_dir/.session.lock"
    
    if [ ! -f "$lock_file" ]; then
        echo "CLOSED:$NC"
        return
    fi
    
    local lock_pid=$(head -n1 "$lock_file" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$lock_pid" ] && _session_nvim_is_process_running "$lock_pid"; then
        echo "ACTIVE:$GREEN"
    else
        echo "STALE:$YELLOW"
    fi
}

# Function to collect all sessions with their info
_session_nvim_collect_sessions() {
    local -n sessions_ref=$1
    local -n counts_ref=$2
    
    sessions_ref=()
    counts_ref=(0 0 0 0)  # [total, active, stale, closed]
    
    [ ! -d "$SESSIONS_DIR" ] && return
    
    for session_dir in "$SESSIONS_DIR"/*/; do
        [ ! -d "$session_dir" ] && continue
        
        local session_name=$(basename "$session_dir")
        local session_path=$(_session_nvim_name_to_path "$session_name")
        local status_info=$(_session_nvim_get_lock_status "$session_dir")
        local status="${status_info%:*}"
        local color="${status_info#*:}"
        
        sessions_ref+=("$session_path:$status:$color:$session_dir")
        
        ((counts_ref[0]++))
        case "$status" in
            "ACTIVE") ((counts_ref[1]++)) ;;
            "STALE")  ((counts_ref[2]++)) ;;
            "CLOSED") ((counts_ref[3]++)) ;;
        esac
    done
}

# Function to display sessions with numbers
_session_nvim_display_sessions() {
    local sessions=("$@")
    
    printf "%-4s %-50s %-10s\n" "NUM" "PATH" "STATUS"
    printf "%-4s %-50s %-10s\n" "---" "----" "------"
    
    local num=1
    for session_info in "${sessions[@]}"; do
        IFS=':' read -r path status color _ <<< "$session_info"
        printf "${color}%-4d %-50s %-10s${NC}\n" "$num" "$path" "$status"
        ((num++))
    done
}

# Function to get user choice for session selection
_session_nvim_get_session_choice() {
    local action="$1"
    local max_count="$2"
    local prompt="Enter session number"
    
    [ "$action" = "delete" ] && prompt="Enter session number to DELETE"
    
    printf "%s (1-%d): " "$prompt" "$max_count"
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$max_count" ]; then
        echo "$choice"
        return 0
    else
        echo -e "${RED}Invalid session number '$choice'${NC}" >&2
        return 1
    fi
}

# Function to handle session deletion with lock check
_session_nvim_delete_session() {
    local session_info="$1"
    IFS=':' read -r path status _ session_dir <<< "$session_info"
    
    if [ "$status" = "ACTIVE" ]; then
        local lock_file="$session_dir/.session.lock"
        local lock_pid=$(head -n1 "$lock_file" 2>/dev/null | tr -d '[:space:]')
        echo -e "${RED}Error: Cannot delete active session '$path' (PID: $lock_pid)${NC}"
        return 1
    fi
    
    if rm -rf "$session_dir"; then
        echo -e "${GREEN}✓ Session deleted: $path${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to delete session directory${NC}"
        return 1
    fi
}

# Function to handle interactive menu choices
_session_nvim_handle_menu_choice() {
    local action="$1"
    local -n sessions_ref=$2
    
    case "$action" in
        "o"|"O")
            local choice
            choice=$(_session_nvim_get_session_choice "open" "${#sessions_ref[@]}")
            if [ $? -eq 0 ]; then
                local session_info="${sessions_ref[$((choice-1))]}"
                IFS=':' read -r path _ _ _ <<< "$session_info"
                echo -e "${GREEN}Opening session: $path${NC}"
                
                local actual_path="$path"
                [[ "$actual_path" == "~"* ]] && actual_path="${actual_path/#\~/$HOME}"
                nvim "$actual_path"
            fi
            ;;
        "d"|"D")
            local choice
            choice=$(_session_nvim_get_session_choice "delete" "${#sessions_ref[@]}")
            if [ $? -eq 0 ]; then
                local session_info="${sessions_ref[$((choice-1))]}"
                if _session_nvim_delete_session "$session_info"; then
                    echo
                    _session_nvim_interactive  # Re-run menu
                fi
            fi
            ;;
        "c"|"C")
            _session_nvim_clean
            echo
            _session_nvim_interactive  # Re-run menu
            ;;
        "h"|"H")
            _session_nvim_help
            ;;
        "q"|"Q"|"")
            return 0
            ;;
    esac
}

# Main interactive function
_session_nvim_interactive() {
    echo -e "${BLUE}Neovim Session Status${NC}"
    echo "=========================="
    echo
    
    local sessions counts
    _session_nvim_collect_sessions sessions counts
    
    if [ "${counts[0]}" -eq 0 ]; then
        echo -e "${YELLOW}No sessions found${NC}"
        echo
        echo -e "${BLUE}Commands: (c)lean  (h)elp  (q)uit${NC}"
        
        while true; do
            echo -n "Choose action: "
            read -n 1 -r action
            echo
            case "$action" in
                "c"|"C")
                    _session_nvim_clean
                    echo
                    _session_nvim_interactive
                    return
                    ;;
                "h"|"H")
                    _session_nvim_help
                    return
                    ;;
                "q"|"Q"|"")
                    return
                    ;;
            esac
        done
    fi
    
    _session_nvim_display_sessions "${sessions[@]}"
    
    echo
    printf "Summary: ${GREEN}Active:${NC} %d   ${YELLOW}Stale:${NC} %d   ${NC}Closed:${NC} %d   ${BLUE}Total:${NC} %d\n" \
           "${counts[1]}" "${counts[2]}" "${counts[3]}" "${counts[0]}"
    echo
    echo -e "${BLUE}Commands: (o)pen  (d)elete  (c)lean  (h)elp  (q)uit${NC}"
    
    while true; do
        echo -n "Choose action: "
        read -n 1 -r action
        echo
        case "$action" in
            "o"|"O")
                echo -n "Enter session number (1-${#sessions[@]}) or press Enter to cancel: "
                read -r choice
                
                if [ -z "$choice" ]; then
                    continue  # Go back to command prompt
                elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#sessions[@]}" ]; then
                    local session_info="${sessions[$((choice-1))]}"
                    IFS=':' read -r path status _ _ <<< "$session_info"
                    
                    # Check if session is active and confirm
                    if [ "$status" = "ACTIVE" ]; then
                        echo -n "Session is already active. Open anyway? (y/N): "
                        read -r confirm
                        if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                            continue  # Go back to command prompt
                        fi
                    fi
                    
                    echo -e "${GREEN}Opening session: $path${NC}"
                    
                    local actual_path="$path"
                    [[ "$actual_path" == "~"* ]] && actual_path="${actual_path/#\~/$HOME}"
                    nvim "$actual_path"
                    return
                else
                    echo -e "${RED}Invalid session number '$choice'${NC}"
                fi
                ;;
            "d"|"D")
                echo -n "Enter session number to DELETE (1-${#sessions[@]}) or press Enter to cancel: "
                read -r choice
                
                if [ -z "$choice" ]; then
                    continue  # Go back to command prompt
                elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#sessions[@]}" ]; then
                    local session_info="${sessions[$((choice-1))]}"
                    IFS=':' read -r path status _ _ <<< "$session_info"
                    
                    # Check if session is active and warn
                    if [ "$status" = "ACTIVE" ]; then
                        echo -n "Session is currently active. Delete anyway? (y/N): "
                        read -r confirm
                        if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                            continue  # Go back to command prompt
                        fi
                    fi
                    
                    if _session_nvim_delete_session "$session_info"; then
                        echo
                        _session_nvim_interactive
                        return
                    fi
                else
                    echo -e "${RED}Invalid session number '$choice'${NC}"
                fi
                ;;
            "c"|"C")
                _session_nvim_clean
                echo
                _session_nvim_interactive
                return
                ;;
            "h"|"H")
                _session_nvim_help
                return
                ;;
            "q"|"Q")
                return
                ;;
            "")
                # Ignore empty input (Enter key)
                ;;
            *)
                # Ignore unrecognized input
                ;;
        esac
    done
}

# Function to clean stale locks
_session_nvim_clean() {
    echo -e "${BLUE}Cleaning stale session locks...${NC}"
    
    if [ ! -d "$SESSIONS_DIR" ]; then
        echo -e "${YELLOW}No sessions directory found at: $SESSIONS_DIR${NC}"
        return 1
    fi
    
    local cleaned=0
    for session_dir in "$SESSIONS_DIR"/*/; do
        [ ! -d "$session_dir" ] && continue
        
        local lock_file="$session_dir/.session.lock"
        if [ -f "$lock_file" ]; then
            local lock_pid=$(head -n1 "$lock_file" 2>/dev/null | tr -d '[:space:]')
            if [ -n "$lock_pid" ] && ! _session_nvim_is_process_running "$lock_pid"; then
                local session_path=$(_session_nvim_name_to_path "$(basename "$session_dir")")
                echo "  Removing stale lock for $session_path (PID $lock_pid)"
                rm "$lock_file"
                ((cleaned++))
            fi
        fi
    done
    
    if [ "$cleaned" -eq 0 ]; then
        echo "  No stale locks found"
    else
        echo -e "${GREEN}  Cleaned $cleaned stale lock(s)${NC}"
    fi
}

# Function to find matching sessions
_session_nvim_find_matches() {
    local pattern="$1"
    local -n matches_ref=$2
    
    matches_ref=()
    [ ! -d "$SESSIONS_DIR" ] && return
    
    for session_dir in "$SESSIONS_DIR"/*/; do
        [ ! -d "$session_dir" ] && continue
        
        local session_path=$(_session_nvim_name_to_path "$(basename "$session_dir")")
        [[ "$session_path" == *"$pattern"* ]] && matches_ref+=("$session_path")
    done
}

# Function to open a session or directory
_session_nvim_open() {
    local session_pattern="$1"
    
    if [ -z "$session_pattern" ]; then
        local sessions counts
        _session_nvim_collect_sessions sessions counts
        
        if [ "${counts[0]}" -eq 0 ]; then
            echo -e "${YELLOW}No sessions found${NC}"
            return 1
        fi
        
        echo -e "${BLUE}Available sessions:${NC}"
        for i in "${!sessions[@]}"; do
            IFS=':' read -r path _ _ _ <<< "${sessions[i]}"
            echo "  $((i+1))) $path"
        done
        
        echo
        echo -n "Enter session number (1-${#sessions[@]}) or press Enter to cancel: "
        read -r choice
        
        if [ -z "$choice" ]; then
            return 0  # Cancel silently
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#sessions[@]}" ]; then
            IFS=':' read -r path _ _ _ <<< "${sessions[$((choice-1))]}"
            echo -e "${GREEN}Opening session: $path${NC}"
            
            local actual_path="$path"
            [[ "$actual_path" == "~"* ]] && actual_path="${actual_path/#\~/$HOME}"
            nvim "$actual_path"
        else
            echo -e "${RED}Invalid session number '$choice'${NC}"
            return 1
        fi
        return
    fi
    
    local matches
    _session_nvim_find_matches "$session_pattern" matches
    
    if [ "${#matches[@]}" -eq 1 ]; then
        local session_path="${matches[0]}"
        echo -e "${GREEN}Opening session: $session_path${NC}"
        
        local actual_path="$session_path"
        [[ "$actual_path" == "~"* ]] && actual_path="${actual_path/#\~/$HOME}"
        nvim "$actual_path"
        
    elif [ "${#matches[@]}" -gt 1 ]; then
        echo -e "${YELLOW}Multiple sessions found matching '$session_pattern':${NC}"
        for i in "${!matches[@]}"; do
            echo "  $((i+1))) ${matches[i]}"
        done
        
        echo
        echo -n "Enter session number (1-${#matches[@]}) or press Enter to cancel: "
        read -r choice
        
        if [ -z "$choice" ]; then
            return 0  # Cancel silently
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#matches[@]}" ]; then
            local selected="${matches[$((choice-1))]}"
            echo -e "${GREEN}Opening session: $selected${NC}"
            
            local actual_path="$selected"
            [[ "$actual_path" == "~"* ]] && actual_path="${actual_path/#\~/$HOME}"
            nvim "$actual_path"
        else
            echo -e "${RED}Invalid selection${NC}"
            return 1
        fi
        
    else
        # No session matches found, treat as regular path
        local target_path="$session_pattern"
        [[ "$target_path" == "~"* ]] && target_path="${target_path/#\~/$HOME}"
        [[ "$target_path" != /* ]] && target_path="$(pwd)/$target_path"
        
        if [ -f "$target_path" ]; then
            echo -e "${RED}Error: session-nvim open only works with directories, not files${NC}"
            echo -e "${YELLOW}Use 'nvim $session_pattern' to open files directly${NC}"
            return 1
        elif [ -d "$target_path" ]; then
            echo -e "${GREEN}Opening directory: $target_path${NC}"
            nvim "$target_path"
        else
            echo -e "${RED}Error: Directory does not exist: $target_path${NC}"
            return 1
        fi
    fi
}

# Function to delete a session
_session_nvim_delete() {
    local session_pattern="$1"
    
    if [ -z "$session_pattern" ]; then
        local sessions counts
        _session_nvim_collect_sessions sessions counts
        
        if [ "${counts[0]}" -eq 0 ]; then
            echo -e "${YELLOW}No sessions found${NC}"
            return 1
        fi
        
        echo -e "${BLUE}Available sessions to delete:${NC}"
        for i in "${!sessions[@]}"; do
            IFS=':' read -r path _ _ _ <<< "${sessions[i]}"
            echo "  $((i+1))) $path"
        done
        
        echo
        echo -n "Enter session number to DELETE (1-${#sessions[@]}) or press Enter to cancel: "
        read -r choice
        
        if [ -z "$choice" ]; then
            return 0  # Cancel silently
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#sessions[@]}" ]; then
            _session_nvim_delete_session "${sessions[$((choice-1))]}"
        else
            echo -e "${RED}Invalid selection${NC}"
            return 1
        fi
        return
    fi
    
    # Look for exact match only
    for session_dir in "$SESSIONS_DIR"/*/; do
        [ ! -d "$session_dir" ] && continue
        
        local session_path=$(_session_nvim_name_to_path "$(basename "$session_dir")")
        if [ "$session_path" = "$session_pattern" ]; then
            local status_info=$(_session_nvim_get_lock_status "$session_dir")
            local session_info="$session_path:${status_info%:*}::$session_dir"
            _session_nvim_delete_session "$session_info"
            return
        fi
    done
    
    echo -e "${RED}Error: No session found with exact path '$session_pattern'${NC}"
    echo -e "${YELLOW}Use 'session-nvim delete' without arguments to see available sessions${NC}"
    return 1
}

# Show help
_session_nvim_help() {
    cat << 'EOF'
Neovim Session Management
========================

Usage: session-nvim [command] [args...]

Commands:
  open [pattern]            - Open a session by pattern or directory
  delete <exact_path>       - Delete a session by exact path
  clean                     - Remove stale session locks
  --help, -h, help          - Show this help

Interactive Mode (default):
  session-nvim              - Show sessions with interactive menu
    (o)pen    - Choose session number to open
    (d)elete  - Choose session number to delete
    (c)lean   - Remove stale locks
    --help    - Show this help

Session Status:
  ACTIVE - Session currently open in Neovim
  STALE  - Lock file exists but process is dead
  CLOSED - No lock file, session is available

Examples:
  session-nvim              # Interactive menu
  session-nvim open         # Interactive session picker
  session-nvim open frontend# Open session matching 'frontend'
  session-nvim open ~/proj  # Open directory (creates new session)
  session-nvim delete ~/old # Delete specific session
  session-nvim clean        # Remove stale locks

Notes:
  - 'open' supports pattern matching and directory creation
  - 'delete' requires exact session paths
  - Files are not supported for 'open' - use 'nvim filename' directly
  - Your terminal working directory remains unchanged
EOF
}

# Main session-nvim function
session-nvim() {
    local command="$1"
    shift
    
    case "$command" in
        "open")    _session_nvim_open "$@" ;;
        "delete")  _session_nvim_delete "$@" ;;
        "clean")   _session_nvim_clean ;;
        ""|*)      
            if [ -n "$command" ] && [[ ! "$command" =~ ^(-h|--help|help)$ ]]; then
                echo -e "${RED}Error: Unknown command '$command'${NC}"
                echo
            fi
            
            [[ "$command" =~ ^(-h|--help|help)$ ]] && _session_nvim_help || _session_nvim_interactive
            ;;
    esac
}
