#!/bin/bash

# Check if a URL argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <URL>"
  echo "Example: $0 https://chat.openai.com"
  exit 1
fi

# Open the URL in Google Chrome's app mode
google-chrome-stable --app="$1"
