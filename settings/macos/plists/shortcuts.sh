#!/bin/bash

# Disable Spotlight shortcut (Cmd+Space)
echo "Disabling Spotlight shortcut (Cmd+Space)..."
# Attempt to add the 'enabled=false' setting for key 64. Ignore errors if the key already exists.
/usr/libexec/PlistBuddy "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" \
  -c "Add :AppleSymbolicHotKeys:64:enabled bool false" > /dev/null 2>&1 || true 
