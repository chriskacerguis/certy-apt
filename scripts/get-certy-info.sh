#!/bin/bash
# Helper script to fetch dynamic information about Certy from GitHub
# This can be sourced by other scripts to get the latest info

# Function to fetch latest release info from GitHub
get_latest_release_info() {
    local repo="${1:-chriskacerguis/certy}"
    local api_url="https://api.github.com/repos/${repo}/releases/latest"
    
    # Fetch release info
    local release_json
    if command -v curl &> /dev/null; then
        release_json=$(curl -s "$api_url")
    else
        echo "Error: curl not found" >&2
        return 1
    fi
    
    # Extract information
    if command -v jq &> /dev/null; then
        # Use jq if available for better JSON parsing
        echo "$release_json" | jq -r '.tag_name, .name, .body' 2>/dev/null
    else
        # Fallback to grep/sed
        echo "$release_json" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/"tag_name": *"\(.*\)"/\1/'
    fi
}

# Function to fetch README content from GitHub
get_readme_content() {
    local repo="${1:-chriskacerguis/certy}"
    local readme_url="https://raw.githubusercontent.com/${repo}/main/README.md"
    
    if command -v curl &> /dev/null; then
        curl -s "$readme_url"
    else
        echo "Error: curl not found" >&2
        return 1
    fi
}

# Function to extract features from README
extract_features_from_readme() {
    local readme_content="$1"
    
    # Extract lines between ## Features and next ##
    echo "$readme_content" | sed -n '/^## Features/,/^##[^#]/p' | \
        grep -E '^\*|^•|^-' | \
        sed 's/^[*•-] *//'
}

# Function to extract examples from README
extract_examples_from_readme() {
    local readme_content="$1"
    
    # Extract code blocks and their descriptions
    echo "$readme_content" | sed -n '/^## Examples/,/^##[^#]/p' | \
        grep -E '^```|^certy|^#' | \
        grep -v '^```$'
}

# Function to extract CLI flags from help output
parse_help_output() {
    local help_text="$1"
    
    # Parse flags in format: -flag description
    echo "$help_text" | grep -E '^\s*-[a-zA-Z]' | while IFS= read -r line; do
        local flag=$(echo "$line" | sed -E 's/^\s*(-[a-zA-Z0-9-]+).*/\1/')
        local desc=$(echo "$line" | sed -E 's/^\s*-[a-zA-Z0-9-]+\s+//')
        
        if [ -n "$flag" ]; then
            echo "$flag|$desc"
        fi
    done
}

# Function to get version from binary
get_binary_version() {
    local binary_path="$1"
    
    if [ ! -x "$binary_path" ]; then
        echo "Error: Binary not found or not executable: $binary_path" >&2
        return 1
    fi
    
    # Try different version flags
    "$binary_path" --version 2>&1 | head -1 || \
    "$binary_path" -version 2>&1 | head -1 || \
    echo "unknown"
}

# Function to get help text from binary
get_binary_help() {
    local binary_path="$1"
    
    if [ ! -x "$binary_path" ]; then
        echo "Error: Binary not found or not executable: $binary_path" >&2
        return 1
    fi
    
    # Try different help flags
    "$binary_path" -h 2>&1 || \
    "$binary_path" --help 2>&1 || \
    "$binary_path" -help 2>&1 || \
    echo ""
}

# Function to generate man page OPTIONS section from help
generate_man_options_from_help() {
    local help_text="$1"
    
    echo ".SH OPTIONS"
    
    # Parse help output
    echo "$help_text" | grep -E '^\s*-' | while IFS= read -r line; do
        local flag=$(echo "$line" | sed -E 's/^\s*(-[a-zA-Z0-9-]+).*/\1/')
        local desc=$(echo "$line" | sed -E 's/^\s*-[a-zA-Z0-9-]+\s+//' | sed 's/$//')
        
        if [ -n "$flag" ] && [ -n "$desc" ]; then
            echo ".TP"
            echo ".B ${flag}"
            echo "${desc}"
        fi
    done
}

# Function to generate man page EXAMPLES section from README
generate_man_examples_from_readme() {
    local readme_content="$1"
    
    echo ".SH EXAMPLES"
    
    # Extract examples section
    local in_examples=0
    local current_title=""
    
    echo "$readme_content" | while IFS= read -r line; do
        if [[ "$line" =~ ^##\ Examples ]]; then
            in_examples=1
            continue
        elif [[ "$line" =~ ^##\  ]] && [ $in_examples -eq 1 ]; then
            break
        fi
        
        if [ $in_examples -eq 1 ]; then
            if [[ "$line" =~ ^###\  ]]; then
                current_title=$(echo "$line" | sed 's/^### *//')
                echo ".SS ${current_title}"
            elif [[ "$line" =~ ^\`\`\`bash ]] || [[ "$line" =~ ^\`\`\`sh ]]; then
                echo ".nf"
                continue
            elif [[ "$line" =~ ^\`\`\`$ ]]; then
                echo ".fi"
                continue
            elif [[ "$line" =~ ^certy\  ]] || [[ "$line" =~ ^#\  ]]; then
                echo ".B ${line}"
            fi
        fi
    done
}

# Function to cache GitHub data to avoid rate limiting
cache_github_data() {
    local cache_dir="${TMPDIR:-/tmp}/certy-apt-cache"
    local cache_file="${cache_dir}/github_data.cache"
    local cache_ttl=3600  # 1 hour
    
    mkdir -p "$cache_dir"
    
    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [ "$cache_age" -lt "$cache_ttl" ]; then
            cat "$cache_file"
            return 0
        fi
    fi
    
    # Fetch fresh data
    local data
    data=$(get_readme_content)
    
    if [ $? -eq 0 ] && [ -n "$data" ]; then
        echo "$data" > "$cache_file"
        echo "$data"
        return 0
    else
        # Return cached data even if expired, if available
        if [ -f "$cache_file" ]; then
            cat "$cache_file"
        fi
        return 1
    fi
}

# Export functions if sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f get_latest_release_info
    export -f get_readme_content
    export -f extract_features_from_readme
    export -f extract_examples_from_readme
    export -f parse_help_output
    export -f get_binary_version
    export -f get_binary_help
    export -f generate_man_options_from_help
    export -f generate_man_examples_from_readme
    export -f cache_github_data
fi

# If run directly, show usage
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "Certy Dynamic Info Helper"
    echo "========================="
    echo ""
    echo "This script provides functions to fetch dynamic information about Certy."
    echo ""
    echo "Usage: source this script and call the functions, or run directly to test:"
    echo ""
    echo "  get_latest_release_info    - Get latest release version"
    echo "  get_readme_content         - Fetch README from GitHub"
    echo "  get_binary_version <path>  - Get version from binary"
    echo "  get_binary_help <path>     - Get help text from binary"
    echo ""
    echo "Example:"
    echo "  source scripts/get-certy-info.sh"
    echo "  VERSION=\$(get_latest_release_info)"
    echo "  README=\$(cache_github_data)"
fi
