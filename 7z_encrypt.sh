#!/bin/bash
# Interactive script to encrypt files in 7z format
# Enhanced version with ASCII art, better error handling, and improved UX

# ASCII Art Banner
show_banner() {
    echo -e "\033[1;36m"
    echo "    ╔══════════════════════════════════════════════════════════════╗"
    echo "    ║                                                              ║"
    echo "    ║                    7-Zip Encryption Tool                     ║"
    echo "    ║                                                              ║"
    echo "    ╚══════════════════════════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo -e "\033[1;33mWelcome to the Enhanced 7-Zip Encryption Tool!\033[0m"
    echo -e "\033[0;90mThis tool will help you encrypt and compress your files securely.\033[0m\n"
}

# Function to show help
show_help() {
    echo -e "\033[1;34m📖 USAGE HELP:\033[0m"
    echo "• Source patterns: /path/to/file, /path/to/*, /path/to/folder/"
    echo "• Compression levels: 0=none, 1=fastest, 3=fast, 5=normal, 7=max, 9=ultra"
    echo "• Use quotes for paths with spaces: \"/path with spaces/*\""
    echo "• Press Ctrl+C to cancel at any time"
    echo ""
}

# Function to validate file pattern
validate_pattern() {
    local pattern="$1"
    
    # Check if pattern is empty
    if [[ -z "$pattern" ]]; then
        echo -e "\033[1;31m❌ Error: No pattern provided.\033[0m"
        return 1
    fi
    
    # Check if pattern exists (handle both files and directories)
    if [[ -f "$pattern" ]] || [[ -d "$pattern" ]]; then
        return 0
    fi
    
    # Check if it's a glob pattern that matches files
    if ls $pattern &> /dev/null 2>&1; then
        return 0
    fi
    
    echo -e "\033[1;31m❌ Error: No files or directories found matching: $pattern\033[0m"
    echo -e "\033[0;90m💡 Tip: Check the path and use quotes for paths with spaces\033[0m"
    return 1
}

# Function to show file info
show_file_info() {
    local pattern="$1"
    echo -e "\033[1;32m📁 Files to encrypt:\033[0m"
    
    if [[ -f "$pattern" ]]; then
        # Single file
        local size=$(du -h "$pattern" | cut -f1)
        echo -e "  📄 $(basename "$pattern") ($size)"
    elif [[ -d "$pattern" ]]; then
        # Directory
        local file_count=$(find "$pattern" -type f | wc -l)
        local total_size=$(du -sh "$pattern" | cut -f1)
        echo -e "  📁 $(basename "$pattern")/ ($file_count files, $total_size)"
    else
        # Glob pattern
        local files=($(ls $pattern 2>/dev/null))
        local file_count=${#files[@]}
        if [[ $file_count -gt 0 ]]; then
            local total_size=$(du -ch $pattern 2>/dev/null | tail -1 | cut -f1)
            echo -e "  📄 $file_count files ($total_size)"
            # Show first few files
            for file in "${files[@]:0:5}"; do
                echo -e "    • $(basename "$file")"
            done
            if [[ $file_count -gt 5 ]]; then
                echo -e "    • ... and $((file_count - 5)) more files"
            fi
        fi
    fi
    echo ""
}

# Function to show progress
show_progress() {
    local message="$1"
    echo -e "\033[1;33m⏳ $message\033[0m"
    echo -e "\033[0;90m   This may take a while depending on file size and compression level...\033[0m"
}

# Check if 7z is installed
if ! command -v 7z &> /dev/null; then
    echo -e "\033[1;31m❌ Error: 7z not found!\033[0m"
    echo -e "\033[0;90m💡 Install with: sudo apt install p7zip-full (Ubuntu/Debian)\033[0m"
    echo -e "\033[0;90m   Or: brew install p7zip (macOS)\033[0m"
    exit 1
fi

# Show banner
show_banner

# Show help option
echo -e "\033[1;34mNeed help? Type 'help' for usage tips, or press Enter to continue.\033[0m"
read -p "Input source path or pattern [e.g., /path/* for all files in folder]: " source_pattern

# Handle help request
if [[ "$source_pattern" == "help" ]]; then
    show_help
    read -p "Input source path or pattern: " source_pattern
fi

# Validate source pattern with enhanced error handling
while ! validate_pattern "$source_pattern"; do
    echo ""
    read -p "Please enter a valid source path or pattern: " source_pattern
    if [[ "$source_pattern" == "help" ]]; then
        show_help
        read -p "Input source path or pattern: " source_pattern
    fi
done

# Show file information
show_file_info "$source_pattern"

# Get destination directory with validation
while true; do
    read -p "Input destination directory [will create if not exists]: " destination_dir
    
    if [[ -z "$destination_dir" ]]; then
        echo -e "\033[1;31m❌ Error: Destination directory cannot be empty.\033[0m"
        continue
    fi
    
    # Create dest dir if needed
    if mkdir -p "$destination_dir" 2>/dev/null; then
        echo -e "\033[1;32m✅ Destination directory ready: $destination_dir\033[0m"
        break
    else
        echo -e "\033[1;31m❌ Error: Cannot create destination directory: $destination_dir\033[0m"
        echo -e "\033[0;90m💡 Check permissions or try a different path\033[0m"
    fi
done

# Get archive filename with validation
while true; do
    read -p "Name your archive [without extension]: " filename
    
    if [[ -z "$filename" ]]; then
        echo -e "\033[1;31m❌ Error: Archive name cannot be empty.\033[0m"
        continue
    fi
    
    # Check for invalid characters
    if [[ "$filename" =~ [^a-zA-Z0-9._-] ]]; then
        echo -e "\033[1;33m⚠️  Warning: Archive name contains special characters.\033[0m"
        echo -e "\033[0;90m   Recommended: Use only letters, numbers, dots, underscores, and hyphens\033[0m"
        read -p "Continue anyway? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            break
        fi
    else
        break
    fi
done

# Enhanced compression level selection
echo -e "\033[1;34m📦 Compression Level Selection:\033[0m"
echo -e "\033[0;90m   0 = None (fastest, no compression)\033[0m"
echo -e "\033[0;90m   1 = Fastest (minimal compression)\033[0m"
echo -e "\033[0;90m   3 = Fast (good balance)\033[0m"
echo -e "\033[0;90m   5 = Normal (default, recommended)\033[0m"
echo -e "\033[0;90m   7 = Maximum (slower, better compression)\033[0m"
echo -e "\033[0;90m   9 = Ultra (slowest, best compression)\033[0m"

while true; do
    read -p "Choose compression level [0-9, default=5]: " level
    # Default to 5 if empty
    level=${level:-5}
    case $level in
        0|1|3|5|7|9) 
            echo -e "\033[1;32m✅ Selected compression level: $level\033[0m"
            break 
            ;;
        *) 
            echo -e "\033[1;31m❌ Invalid level. Choose 0, 1, 3, 5, 7, or 9.\033[0m"
            ;;
    esac
done

# Enhanced password input with strength validation
echo -e "\033[1;34m🔐 Password Setup:\033[0m"
echo -e "\033[0;90m💡 Use a strong password with at least 8 characters, including letters, numbers, and symbols\033[0m"

while true; do
    read -s -p "Enter password: " password
    echo  # Newline after hidden input
    
    # Basic password strength check
    if [[ ${#password} -lt 8 ]]; then
        echo -e "\033[1;33m⚠️  Warning: Password is shorter than 8 characters.\033[0m"
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            continue
        fi
    fi
    
    read -s -p "Confirm password: " password_confirm
    echo
    if [ "$password" = "$password_confirm" ]; then
        echo -e "\033[1;32m✅ Password confirmed successfully!\033[0m"
        break
    else
        echo -e "\033[1;31m❌ Passwords do not match. Please try again.\033[0m"
    fi
done

# Generate archive path with timestamp
archive_path="${destination_dir}/${filename}_$(date '+%Y-%m-%d').7z"

# Show final confirmation
echo -e "\033[1;36m📋 ENCRYPTION SUMMARY:\033[0m"
echo -e "\033[0;90m   Source: $source_pattern\033[0m"
echo -e "\033[0;90m   Destination: $archive_path\033[0m"
echo -e "\033[0;90m   Compression: Level $level\033[0m"
echo ""

# Final confirmation
read -p "Proceed with encryption? (Y/n): " final_confirm
if [[ "$final_confirm" =~ ^[Nn]$ ]]; then
    echo -e "\033[1;33m❌ Encryption cancelled by user.\033[0m"
    exit 0
fi

# Run 7z with enhanced progress indication
echo ""
show_progress "Starting encryption process..."

# Create a temporary file to capture 7z output for better progress indication
temp_log="/tmp/7z_encrypt_$$.log"

# Run 7z with progress indication
if 7z a -mhe=on -mx=$level -p"$password" "$archive_path" $source_pattern > "$temp_log" 2>&1; then
    # Success
    echo -e "\033[1;32m✅ Encryption completed successfully!\033[0m"
    
    # Show archive info
    if [[ -f "$archive_path" ]]; then
        archive_size=$(du -h "$archive_path" | cut -f1)
        echo -e "\033[1;36m📦 Archive created: $(basename "$archive_path")\033[0m"
        echo -e "\033[0;90m   Size: $archive_size\033[0m"
        echo -e "\033[0;90m   Location: $archive_path\033[0m"
    fi
    
    # Show compression ratio if possible
    if command -v 7z &> /dev/null; then
        echo -e "\033[0;90m   Testing archive integrity...\033[0m"
        if 7z t "$archive_path" -p"$password" > /dev/null 2>&1; then
            echo -e "\033[1;32m✅ Archive integrity verified!\033[0m"
        else
            echo -e "\033[1;33m⚠️  Could not verify archive integrity\033[0m"
        fi
    fi
    
else
    # Error handling
    echo -e "\033[1;31m❌ Encryption failed!\033[0m"
    echo -e "\033[0;90mError details:\033[0m"
    cat "$temp_log" | tail -10
    echo ""
    echo -e "\033[0;90m💡 Common issues:\033[0m"
    echo -e "\033[0;90m   • Insufficient disk space\033[0m"
    echo -e "\033[0;90m   • Permission denied\033[0m"
    echo -e "\033[0;90m   • Invalid file paths\033[0m"
    echo -e "\033[0;90m   • Corrupted source files\033[0m"
    
    # Clean up temp file
    rm -f "$temp_log"
    exit 1
fi

# Clean up temp file
rm -f "$temp_log"

# Secure cleanup of sensitive data
unset password
unset password_confirm

# Enhanced results display
echo ""
echo -e "\033[1;36m📁 Destination Directory Contents:\033[0m"
ls -lh "$destination_dir" | while read line; do
    if [[ "$line" == *"$(basename "$archive_path")"* ]]; then
        echo -e "\033[1;32m   $line\033[0m"  # Highlight the new archive
    else
        echo -e "\033[0;90m   $line\033[0m"
    fi
done

echo ""
echo -e "\033[1;33m🎉 Encryption process completed!\033[0m"
echo -e "\033[0;90m💡 Remember to keep your password safe - it cannot be recovered!\033[0m"

# Optional: Ask if user wants to encrypt more files
echo ""
read -p "Encrypt more files? (y/N): " more_files
if [[ "$more_files" =~ ^[Yy]$ ]]; then
    echo -e "\033[1;36m🔄 Starting new encryption session...\033[0m"
    echo ""
    # Restart the script
    exec "$0"
fi

echo -e "\033[1;36m👋 Thank you for using the Enhanced 7-Zip Encryption Tool!\033[0m"
read -p "Press Enter to exit..."

