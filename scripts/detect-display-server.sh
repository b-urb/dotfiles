#!/bin/bash
# Display server detection utility for conditional window manager installation
# Returns: "x11", "wayland", or "unknown"

detect_display_server() {
    # Priority 1: Manual override via environment variable
    if [ -n "$WM_FORCE_DISPLAY_SERVER" ]; then
        case "$WM_FORCE_DISPLAY_SERVER" in
            x11|wayland)
                echo "$WM_FORCE_DISPLAY_SERVER"
                return 0
                ;;
            *)
                echo "Warning: Invalid WM_FORCE_DISPLAY_SERVER value: $WM_FORCE_DISPLAY_SERVER" >&2
                echo "Valid values: x11, wayland" >&2
                ;;
        esac
    fi

    # Priority 2: Check XDG_SESSION_TYPE environment variable
    if [ -n "$XDG_SESSION_TYPE" ]; then
        case "$XDG_SESSION_TYPE" in
            x11|wayland)
                echo "$XDG_SESSION_TYPE"
                return 0
                ;;
        esac
    fi

    # Priority 3: Check loginctl if available
    if command -v loginctl &>/dev/null; then
        # Get current session ID
        local session_id=$(loginctl | grep "$(whoami)" | awk '{print $1}' | head -1)
        if [ -n "$session_id" ]; then
            local session_type=$(loginctl show-session "$session_id" -p Type --value 2>/dev/null)
            case "$session_type" in
                x11|wayland)
                    echo "$session_type"
                    return 0
                    ;;
            esac
        fi
    fi

    # Priority 4: Check for running display server processes
    if pgrep -x "Xorg" >/dev/null 2>&1 || pgrep -x "X" >/dev/null 2>&1; then
        echo "x11"
        return 0
    fi

    if pgrep -x "sway" >/dev/null 2>&1 || pgrep -x "weston" >/dev/null 2>&1 || pgrep -x "mutter" >/dev/null 2>&1; then
        echo "wayland"
        return 0
    fi

    # Fallback: Could not detect
    echo "unknown"
    return 1
}

# If script is executed directly, run detection and print result
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    result=$(detect_display_server)
    echo "Display server: $result"
    exit $?
fi
