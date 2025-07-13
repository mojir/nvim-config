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

# Function to list sessions with interactive menu
_session_nvim_interactive() {
    echo -e "${BLUE}Neovim Session Status${NC}"
    echo "=========================="
    echo
    
    if [ ! -d "$SESSIONS_DIR" ]; then
        echo -e "${YELLOW}No sessions directory found at: $SESSIONS_DIR${NC}"
        echo
        echo -e "${BLUE}Commands: (c)lean  --help${NC}"
        echo -n "Choose action: "
        read -r action
        
        case "$action" in
            "c"|"clean")
                _session_nvim_clean
                ;;
            "--help"|"-h"|"help")
                _session_nvim_help
                ;;
            "")
                return 0
                ;;
            *)
                echo -e "${RED}Invalid action '$action'${NC}"
                return 1
                ;;
        esac
        return
    fi
    
    local session_count=0
    local active_count=0
    local stale_count=0
    local closed_count=0
    local all_sessions=()
    
    # Header
    printf "%-4s %-50s %-10s\n" "NUM" "PATH" "STATUS"
    printf "%-4s %-50s %-10s\n" "---" "----" "------"
    
    # Find all session directories
    local num=1
    for session_dir in "$SESSIONS_DIR"/*/; do
        if [ ! -d "$session_dir" ]; then
            continue
        fi
        
        session_count=$((session_count + 1))
        
        local session_name=$(basename "$session_dir")
        local session_path=$(_nvim_session_name_to_path "$session_name")
        all_sessions+=("$session_path")
        
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
        
        # Print session info with number
        printf "${status_color}%-4d %-50s %-10s${NC}\n" \
            "$num" \
            "$session_path" \
            "$status"
        
        ((num++))
    done
    
    if [ $session_count -eq 0 ]; then
        echo -e "${YELLOW}No sessions found${NC}"
        echo
        echo -e "${BLUE}Commands: (c)lean  (h)elp  (q)uit${NC}"
        
        while true; do
            echo -n "Choose action: "
            read -n 1 -r action
            echo  # Add newline after single character input
            
            case "$action" in
                "c"|"C")
                    _session_nvim_clean
                    echo
                    # Re-run the interactive menu 
                    _session_nvim_interactive
                    return 0
                    ;;
                "h"|"H")
                    _session_nvim_help
                    break
                    ;;
                "q"|"Q"|"")
                    return 0
                    ;;
                *)
                    # Silently ignore unrecognized input and continue loop
                    ;;
            esac
        done
        return
    fi
    
    echo
    echo "Summary:"
    echo -e "  ${GREEN}Active:${NC} $active_count   ${YELLOW}Stale:${NC} $stale_count   ${NC}Closed:${NC} $closed_count   ${BLUE}Total:${NC} $session_count"
    echo
    echo -e "${BLUE}Commands: (o)pen  (d)elete  (c)lean  (h)elp  (q)uit${NC}"
    
    while true; do
        echo -n "Choose action: "
        read -n 1 -r action
        echo  # Add newline after single character input
        
        case "$action" in
            "o"|"O")
                echo -n "Enter session number (1-$session_count): "
                read -r choice
                
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$session_count" ]; then
                    local selected="${all_sessions[$((choice-1))]}"
                    
                    echo -e "${GREEN}Opening session: $selected${NC}"
                    
                    # Expand ~ to home directory
                    local actual_path="$selected"
                    if [[ "$actual_path" == "~"* ]]; then
                        actual_path="${actual_path/#\~/$HOME}"
                    fi
                    
                    nvim "$actual_path"
                else
                    echo -e "${RED}Invalid session number '$choice'${NC}"
                    return 1
                fi
                break
                ;;
            "d"|"D")
                echo -n "Enter session number to DELETE (1-$session_count): "
                read -r choice
                
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$session_count" ]; then
                    local selected="${all_sessions[$((choice-1))]}"
                    
                    # Find the session directory and check if active
                    for session_dir in "$SESSIONS_DIR"/*/; do
                        if [ ! -d "$session_dir" ]; then
                            continue
                        fi
                        
                        local session_name=$(basename "$session_dir")
                        local session_path=$(_nvim_session_name_to_path "$session_name")
                        
                        if [ "$session_path" = "$selected" ]; then
                            # Check if session is currently active
                            local lock_file="$session_dir/.session.lock"
                            if [ -f "$lock_file" ]; then
                                local lock_content=$(cat "$lock_file" 2>/dev/null)
                                local lock_pid=$(echo "$lock_content" | head -n1 | tr -d '[:space:]')
                                
                                if [ -n "$lock_pid" ] && _nvim_session_is_process_running "$lock_pid"; then
                                    echo -e "${RED}Error: Cannot delete active session '$session_path' (PID: $lock_pid)${NC}"
                                    return 1
                                fi
                            fi
                            
                            # Delete the session
                            rm -rf "$session_dir"
                            if [ $? -eq 0 ]; then
                                echo -e "${GREEN}✓ Session deleted: $session_path${NC}"
                                echo
                                # Re-run the interactive menu to show updated list
                                _session_nvim_interactive
                                return 0
                            else
                                echo -e "${RED}✗ Failed to delete session directory${NC}"
                                return 1
                            fi
                        fi
                    done
                else
                    echo -e "${RED}Invalid session number '$choice'${NC}"
                    return 1
                fi
                ;;
            "c"|"C")
                _session_nvim_clean
                echo
                # Re-run the interactive menu to show updated statuses
                _session_nvim_interactive
                return 0
                ;;
            "h"|"H")
                _session_nvim_help
                break
                ;;
            "q"|"Q"|"")
                return 0
                ;;
            *)
                # Silently ignore unrecognized input and continue loop
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

# Function to open a session or directory
_session_nvim_open() {
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
            
            # Expand ~ to home directory for the path
            local actual_path="$selected"
            if [[ "$actual_path" == "~"* ]]; then
                actual_path="${actual_path/#\~/$HOME}"
            fi
            
            # Open nvim with the directory path
            nvim "$actual_path"
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
        
        # Expand ~ to home directory
        local actual_path="$session_path"
        if [[ "$actual_path" == "~"* ]]; then
            actual_path="${actual_path/#\~/$HOME}"
        fi
        
        # Open nvim with the directory path
        nvim "$actual_path"
        
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
            
            # Expand ~ to home directory
            local actual_path="$selected"
            if [[ "$actual_path" == "~"* ]]; then
                actual_path="${actual_path/#\~/$HOME}"
            fi
            
            # Open nvim with the directory path
            nvim "$actual_path"
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
        
        # Check if the path exists and what type it is
        if [ -f "$target_path" ]; then
            echo -e "${RED}Error: session-nvim open only works with directories, not files${NC}"
            echo -e "${YELLOW}Use 'nvim $session_pattern' to open files directly${NC}"
            return 1
        elif [ -d "$target_path" ]; then
            echo -e "${GREEN}Opening directory: $target_path${NC}"
            # Open nvim with the directory path
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
        
        echo -e "${BLUE}Available sessions to delete:${NC}"
        local i=1
        for session_path in "${all_sessions[@]}"; do
            echo "  $i) $session_path"
            ((i++))
        done
        echo
        echo "Choose a session number to DELETE (1-$((i-1))):"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
            local selected="${all_sessions[$((choice-1))]}"
            
            # Find and delete the session
            for session_dir in "$SESSIONS_DIR"/*/; do
                if [ ! -d "$session_dir" ]; then
                    continue
                fi
                
                local session_name=$(basename "$session_dir")
                local session_path=$(_nvim_session_name_to_path "$session_name")
                
                if [ "$session_path" = "$selected" ]; then
                    # Check if session is currently active
                    local lock_file="$session_dir/.session.lock"
                    if [ -f "$lock_file" ]; then
                        local lock_content=$(cat "$lock_file" 2>/dev/null)
                        local lock_pid=$(echo "$lock_content" | head -n1 | tr -d '[:space:]')
                        
                        if [ -n "$lock_pid" ] && _nvim_session_is_process_running "$lock_pid"; then
                            echo -e "${RED}Error: Cannot delete active session '$session_path' (PID: $lock_pid)${NC}"
                            return 1
                        fi
                    fi
                    
                    # Delete the session
                    rm -rf "$session_dir"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}✓ Session deleted: $session_path${NC}"
                    else
                        echo -e "${RED}✗ Failed to delete session directory${NC}"
                        return 1
                    fi
                    return 0
                fi
            done
        else
            echo -e "${RED}Invalid selection${NC}"
            return 1
        fi
        return 0
    fi
    
    # Look for EXACT match only
    for session_dir in "$SESSIONS_DIR"/*/; do
        if [ ! -d "$session_dir" ]; then
            continue
        fi
        
        local session_name=$(basename "$session_dir")
        local session_path=$(_nvim_session_name_to_path "$session_name")
        
        # Check for exact match only
        if [ "$session_path" = "$session_pattern" ]; then
            # Check if session is currently active
            local lock_file="$session_dir/.session.lock"
            if [ -f "$lock_file" ]; then
                local lock_content=$(cat "$lock_file" 2>/dev/null)
                local lock_pid=$(echo "$lock_content" | head -n1 | tr -d '[:space:]')
                
                if [ -n "$lock_pid" ] && _nvim_session_is_process_running "$lock_pid"; then
                    echo -e "${RED}Error: Cannot delete active session '$session_path' (PID: $lock_pid)${NC}"
                    return 1
                fi
            fi
            
            # Delete the session
            rm -rf "$session_dir"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Session deleted: $session_path${NC}"
            else
                echo -e "${RED}✗ Failed to delete session directory${NC}"
                return 1
            fi
            return 0
        fi
    done
    
    # No exact match found
    echo -e "${RED}Error: No session found with exact path '$session_pattern'${NC}"
    echo -e "${YELLOW}Use 'session-nvim delete' without arguments to see available sessions${NC}"
    return 1
}

# Show help
_session_nvim_help() {
    echo "Neovim Session Management"
    echo "========================"
    echo
    echo "Usage: session-nvim [command] [args...]"
    echo
    echo "Commands:"
    echo "  open [pattern]            - Open a session by pattern or directory"
    echo "  delete <exact_path>       - Delete a session by exact path"
    echo "  clean                     - Remove stale session locks"
    echo "  --help, -h, help          - Show this help"
    echo
    echo "Interactive Mode (default):"
    echo "  session-nvim              - Show sessions with interactive menu"
    echo "    (o)pen    - Choose session number to open"
    echo "    (d)elete  - Choose session number to delete"
    echo "    (c)lean   - Remove stale locks"
    echo "    --help    - Show this help"
    echo
    echo "Session Status:"
    echo "  ACTIVE - Session currently open in Neovim"
    echo "  STALE  - Lock file exists but process is dead"
    echo "  CLOSED - No lock file, session is available"
    echo
    echo "Examples:"
    echo "  session-nvim              # Interactive menu"
    echo "  session-nvim open         # Interactive session picker"
    echo "  session-nvim open frontend# Open session matching 'frontend'"
    echo "  session-nvim open ~/proj  # Open directory (creates new session)"
    echo "  session-nvim delete ~/old # Delete specific session"
    echo "  session-nvim clean        # Remove stale locks"
    echo
    echo "Notes:"
    echo "  - 'open' supports pattern matching and directory creation"
    echo "  - 'delete' requires exact session paths"
    echo "  - Files are not supported for 'open' - use 'nvim filename' directly"
    echo "  - Your terminal working directory remains unchanged"
}

# Main session-nvim function
session-nvim() {
    local command="$1"
    shift  # Remove command from arguments
    
    case "$command" in
        "open")
            _session_nvim_open "$@"
            ;;
        "delete")
            _session_nvim_delete "$@"
            ;;
        "clean")
            _session_nvim_clean
            ;;
        ""|*)
            # No command or unknown command - show interactive menu
            if [ -n "$command" ] && [ "$command" != "--help" ] && [ "$command" != "-h" ] && [ "$command" != "help" ]; then
                echo -e "${RED}Error: Unknown command '$command'${NC}"
                echo
            fi
            
            if [ "$command" = "--help" ] || [ "$command" = "-h" ] || [ "$command" = "help" ]; then
                _session_nvim_help
            else
                _session_nvim_interactive
            fi
            ;;
    esac
}
