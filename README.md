# 7z_encrypt
Interactively encrypt files using 7z simple bash script

### Create an interactive script:

```javascript
sudo nvim /usr/local/bin/7z_encrypt.sh
```

**Paste the following:**

```javascript
#!/bin/bash
# Interactive script to encrypt files in 7z format
# Improvements: Better prompting, path quoting, dir checks, error handling, password security, compression level choice

# Check if 7z is installed
if ! command -v 7z &> /dev/null; then
    echo "Error: 7z not found. Install p7zip-full (e.g., sudo apt install p7zip-full on Ubuntu)."
    exit 1
fi

read -p "Input source path or pattern [e.g., /path/* for all files in folder]: " source_pattern

# Validate source (basic: check if something matches)
if ! ls $source_pattern &> /dev/null; then
    echo "Error: No files found matching source pattern. Check the path."
    exit 1
fi

read -p "Input destination directory [will create if not exists]: " destination_dir

# Create dest dir if needed
mkdir -p "$destination_dir" || { echo "Error creating destination dir."; exit 1; }

read -p "Name your archive [without extension]: " filename

# Prompt for compression level with hint
while true; do
    read -p "Compression level [hint: -mx=0 (none), 1 (fastest), 3 (fast), 5 (normal/default), 7 (max), 9 (ultra)]: " level
    # Default to 5 if empty
    level=${level:-5}
    case $level in
        0|1|3|5|7|9) break ;;
        *) echo "Invalid level. Choose 0,1,3,5,7, or 9." ;;
    esac
done

# Prompt for password securely (twice for confirmation)
while true; do
    read -s -p "Enter password: " password
    echo  # Newline after hidden input
    read -s -p "Confirm password: " password_confirm
    echo
    if [ "$password" = "$password_confirm" ]; then
        break
    else
        echo "Passwords do not match. Try again."
    fi
done

# Generate archive path
archive_path="${destination_dir}/${filename}_$(date '+%Y-%m-%d').7z"

# Run 7z with dynamic compression and password
echo "Encrypting with -mx=$level... This may take a while (higher levels are slower)."
7z a -mhe=on -mx=$level -p"$password" "$archive_path" $source_pattern

# Check if 7z succeeded
if [ $? -eq 0 ]; then
    echo "Done. Archive created: $archive_path"
else
    echo "Error during encryption. Check inputs, disk space, or password."
    exit 1
fi

# Clean up
unset password
unset password_confirm

# List output
echo "Contents of destination dir:"
ls -l "$destination_dir"

read -p "Press Enter to exit..." # Pauses before closing
```

***

### Create a `.desktop` file

**1 - Make sure the script is executable:**

```javascript
sudo chmod +x /usr/local/bin/7z_encrypt.sh
```

**2 - Create the `.desktop` file:**

```javascript
sudo nvim /usr/share/applications/7z_encrypt.desktop
```

**3 - Paste the following:**

```javascript
[Desktop Entry]
Name=7zEncrypt
Comment=Interactively encrypt files using 7z script
Exec=gnome-terminal -- /usr/local/bin/7z_encrypt.sh
Icon=utilities-terminal  # Or path to a custom icon, e.g., /usr/share/icons/hicolor/48x48/apps/archiver.png
Terminal=false  # We launch our own terminal, so this is false
Type=Application
Categories=Utility;Security;
StartupNotify=true
```

**4 - Make the `.desktop` file executable:**

```javascript
sudo chmod +x /usr/share/applications/7z_encrypt.desktop
```

5 - **Place and Test**:

- **On Desktop**: Copy the .desktop file to your Desktop folder (~/Desktop/), or right-click desktop > "Create Launcher" in some DEs, and point to the script with terminal options.
- **In Menu**: It should appear in your applications menu (search for "Encrypt Files with 7z"). Log out/in or run update-desktop-database if needed.
- Click it: Terminal opens, script runs interactively (you'll see prompts and can type inputs).
