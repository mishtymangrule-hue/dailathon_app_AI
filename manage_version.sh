#!/bin/bash

# Version management script for Dailathon Dialer
# Manages version code and version name across build files

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GRADLE_FILE="$SCRIPT_DIR/android/app/build.gradle.kts"
PUBSPEC_FILE="$SCRIPT_DIR/pubspec.yaml"

# Function to show help
show_help() {
    cat << EOF
Usage: ./manage_version.sh [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -s, --show              Show current version
    -u, --update VERSION    Update to specific version (e.g., 1.0.0)
    -i, --increment         Increment patch version (1.0.0 -> 1.0.1)
    -b, --bump-minor        Increment minor version (1.0.0 -> 1.1.0)
    -B, --bump-major        Increment major version (1.0.0 -> 2.0.0)

EXAMPLES:
    ./manage_version.sh --show              # Show current version
    ./manage_version.sh --update 1.0.1      # Set to v1.0.1
    ./manage_version.sh --increment         # Patch increment
    ./manage_version.sh --bump-minor        # Minor increment

EOF
}

# Function to get current version
get_current_version() {
    if [ -f "$PUBSPEC_FILE" ]; then
        grep "^version:" "$PUBSPEC_FILE" | awk '{print $2}'
    fi
}

# Function to get current version code
get_current_version_code() {
    if [ -f "$GRADLE_FILE" ]; then
        grep "versionCode = " "$GRADLE_FILE" | grep -o '[0-9]*' | tail -1
    fi
}

# Function to show version
show_version() {
    echo "Current Version:"
    echo "  Flutter: $(get_current_version)"
    echo "  Android: Version Code: $(get_current_version_code)"
}

# Function to update version
update_version() {
    local new_version=$1
    
    if [ -z "$new_version" ]; then
        echo "ERROR: No version provided"
        exit 1
    fi
    
    # Calculate new version code (e.g., 1.0.0 -> 10000, 1.2.3 -> 10203)
    IFS='.' read -ra PARTS <<< "$new_version"
    local major=${PARTS[0]:-0}
    local minor=${PARTS[1]:-0}
    local patch=${PARTS[2]:-0}
    local new_code=$((major * 10000 + minor * 100 + patch))
    
    echo "Updating version to $new_version (code: $new_code)..."
    
    # Update pubspec.yaml
    if [ -f "$PUBSPEC_FILE" ]; then
        sed -i.bak "s/^version:.*/version: $new_version/" "$PUBSPEC_FILE"
        echo "✓ Updated Flutter version in pubspec.yaml"
    fi
    
    # Update build.gradle.kts
    if [ -f "$GRADLE_FILE" ]; then
        sed -i.bak "s/versionCode = [0-9]*/versionCode = $new_code/" "$GRADLE_FILE"
        sed -i.bak "s/versionName = \".*\"/versionName = \"$new_version\"/" "$GRADLE_FILE"
        echo "✓ Updated Android version in build.gradle.kts"
    fi
    
    # Clean up backup files
    rm -f "$PUBSPEC_FILE.bak" "$GRADLE_FILE.bak"
    
    echo ""
    echo "✓ Version updated successfully!"
    show_version
}

# Function to increment versions
increment_version() {
    local current=$(get_current_version)
    IFS='.' read -ra PARTS <<< "$current"
    
    local major=${PARTS[0]:-0}
    local minor=${PARTS[1]:-0}
    local patch=${PARTS[2]:-0}
    
    case $1 in
        "patch")
            ((patch++))
            ;;
        "minor")
            ((minor++))
            patch=0
            ;;
        "major")
            ((major++))
            minor=0
            patch=0
            ;;
    esac
    
    local new_version="$major.$minor.$patch"
    echo "Incrementing version ($1): $current -> $new_version"
    update_version "$new_version"
}

# Main script logic
case "${1:-}" in
    -h|--help)
        show_help
        ;;
    -s|--show)
        show_version
        ;;
    -u|--update)
        update_version "$2"
        ;;
    -i|--increment)
        increment_version "patch"
        ;;
    -b|--bump-minor)
        increment_version "minor"
        ;;
    -B|--bump-major)
        increment_version "major"
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
