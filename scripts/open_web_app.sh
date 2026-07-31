#!/bin/bash

# Check if a URL argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <URL> [class]"
  echo "Example: $0 https://chat.openai.com openai-app"
  exit 1
fi

# Open the URL in Google Chrome's app mode with optimized Wayland flags
google-chrome-stable --disable-features=Vulkan --ozone-platform-hint=auto --app="$1" &
