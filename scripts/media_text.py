#!/usr/bin/env python3
import subprocess
import json
import sys

def is_emoji_or_symbol(ch):
    o = ord(ch)
    # Filter common emoji and symbol ranges:
    if 0x1F300 <= o <= 0x1F9FF: # Emojis, Symbols, Pictographs, Emoticons
        return True
    if 0x2600 <= o <= 0x27BF:   # Miscellaneous Symbols, Dingbats
        return True
    if 0x2300 <= o <= 0x23FF:   # Miscellaneous Technical
        return True
    if 0x1F000 <= o <= 0x1F2FF: # Playing Cards, Mahjong, Enclosed Ideographic
        return True
    if 0xfe00 <= o <= 0xfe0f:   # Variation Selectors
        return True
    return False

def sanitize_text(text):
    clean = "".join(ch for ch in text if not is_emoji_or_symbol(ch))
    return " ".join(clean.split()).strip()

def format_time(seconds):
    try:
        seconds = int(float(seconds))
        hours = seconds // 3600
        minutes = (seconds % 3600) // 60
        secs = seconds % 60
        if hours > 0:
            return f"{hours:02d}:{minutes:02d}:{secs:02d}"
        return f"{minutes:02d}:{secs:02d}"
    except Exception:
        return "00:00"

def main():
    try:
        # Run playerctl only once to get all info (status, artist, title, position, length)
        proc = subprocess.run(
            ["playerctl", "metadata", "--format", "{{status}};;{{artist}};;{{title}};;{{position}};;{{mpris:length}}"],
            capture_output=True,
            text=True
        )
        if proc.returncode != 0:
            print(json.dumps({"text": ""}))
            sys.exit(0)
            
        output = proc.stdout.strip()
        if not output:
            print(json.dumps({"text": ""}))
            sys.exit(0)
            
        parts = output.split(";;")
        if len(parts) < 5:
            print(json.dumps({"text": ""}))
            sys.exit(0)
            
        status = parts[0].strip()
        artist = parts[1].strip()
        title = parts[2].strip()
        pos_raw = parts[3].strip()
        len_raw = parts[4].strip()
        
        # Hide widget if Stopped or no active title
        if status == "Stopped" or not title:
            print(json.dumps({"text": ""}))
            sys.exit(0)
            
        text = f"{artist} - {title}" if artist else title
        text = sanitize_text(text)
        if not text:
            print(json.dumps({"text": ""}))
            sys.exit(0)
            
        # Format time if available
        time_str = ""
        if pos_raw and len_raw:
            try:
                # position is outputted in seconds by playerctl format
                # mpris:length is in microseconds
                pos_sec = float(pos_raw)
                len_sec = float(len_raw) / 1000000.0
                time_str = f"  <span font_family='monospace'>[{format_time(pos_sec)} / {format_time(len_sec)}]</span>"
            except Exception:
                pass
                
        status_icon = "" if status == "Playing" else ""
        full_text = f"{status_icon}  {text}{time_str}"
        
        out = {"text": full_text, "tooltip": f"Playing: {text}\nStatus: {status}{time_str}"}
        print(json.dumps(out))
        sys.stdout.flush()
    except Exception:
        print(json.dumps({"text": ""}))
        sys.exit(0)

if __name__ == "__main__":
    main()
