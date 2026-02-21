#!/usr/bin/env bash
# torrent_analyzer.sh - Auto-detect torrent type and destination

# Parse torrent name and return JSON
torrent_parse() {
    local filename="$1"
    local type=""
    local series_name=""
    local season=""
    local episode=""
    local quality=""
    
    # Remove extension
    local name="${filename%.*}"
    
    # Remove common suffixes and quality tags FIRST
    name=$(echo "$name" | sed -E 's/(720p|1080p|2160p|4k|UHD|BluRay|DVDRip|HDTV|WEB-DL|WEBRip|BRRip|x264|x265|h264|h265|aac|ac3|dts|mp3|subtitles|spanish|latinamerica|latino).*//gi')
    
    # Clean trailing separators before year check
    name=$(echo "$name" | sed -E 's/[-_\. ]+$//')
    
    # Extract year if present (parentheses, brackets, or at end)
    local year=""
    if echo "$name" | grep -qE '\([0-9]{4}\)$'; then
        year=$(echo "$name" | grep -oE '\([0-9]{4}\)$' | tr -d '()')
        name=$(echo "$name" | sed -E 's/\([0-9]{4}\)$//')
    elif echo "$name" | grep -qE '\[[0-9]{4}\]$'; then
        year=$(echo "$name" | grep -oE '\[[0-9]{4}\]$' | tr -d '[]')
        name=$(echo "$name" | sed -E 's/\[[0-9]{4}\]$//')
    elif echo "$name" | grep -qE '[0-9]{4}$'; then
        year=$(echo "$name" | grep -oE '[0-9]{4}$' | tail -1)
        name=$(echo "$name" | sed -E 's/[0-9]{4}$//')
    fi
    
    name=$(echo "$name" | sed -E 's/[-_\. ]+$//')
    
    # Determine type based on patterns (in order of specificity)
    # Episode patterns (most specific) - S01E02, s1e2, 1x02
    if echo "$name" | grep -qiE 's[0-9]+e[0-9]+|[0-9]+x[0-9]+'; then
        type="episode"
        if echo "$name" | grep -qiE 's[0-9]+e[0-9]+'; then
            season=$(echo "$name" | grep -oE '[sS][0-9]+' | grep -oE '[0-9]+' | head -1)
            episode=$(echo "$name" | grep -oE '[eE][0-9]+' | grep -oE '[0-9]+' | head -1)
        else
            season=$(echo "$name" | grep -oE '[0-9]+x[0-9]+' | grep -oE '^[0-9]+')
            episode=$(echo "$name" | grep -oE '[0-9]+x[0-9]+' | grep -oE 'x[0-9]+$' | tr -d 'x')
        fi
        name=$(echo "$name" | sed -E 's/[sS][0-9]+[eE][0-9]+.*//' | sed -E 's/[0-9]+x[0-9]+.*//' | sed -E 's/[-_\. ]+$//')
    # Season pattern - S01, Season 1
    elif echo "$name" | grep -qiE 's[0-9]+$'; then
        type="season"
        season=$(echo "$name" | grep -oE '[sS][0-9]+' | grep -oE '[0-9]+' | tail -1)
        name=$(echo "$name" | sed -E 's/[sS][0-9]+.*$//' | sed -E 's/[-_\. ]+$//')
    # Movie pattern - has year
    elif [ -n "$year" ]; then
        type="movie"
    # Default to series
    else
        type="series"
    fi
    
    # Clean up series name
    series_name=$(echo "$name" | sed -E 's/[-_\.]+/ /g' | xargs)
    
    # Extract quality
    if echo "$filename" | grep -qiE '720p|1080p|2160p|4K|UHD'; then
        quality=$(echo "$filename" | grep -oiE '720p|1080p|2160p|4k|UHD' | head -1)
    fi
    
    # Output as JSON
    cat <<EOF
{
  "type": "$type",
  "series_name": "$series_name",
  "season": "$season",
  "episode": "$episode",
  "quality": "$quality"
}
EOF
}

# Test function
test_analyzer() {
    local tests=(
        "El.caballero.de.los.Siete.Reinos.1x02.1080p.mkv"
        "Breaking.Bad.S01E05.720p.mkv"
        "The.Office.S01.1080p.mkv"
        "Dune.Part.Two.2024.2160p.mkv"
        "Game.of.Thrones.S08E03.mkv"
        "The.Pitt.S02E04.mkv"
        "Marvels.What.If.S01.1080p.mkv"
        "The.Last.of Us.S01E01.4K.mkv"
        "Oppenheimer.2023.4K.mkv"
        "Avatar.The.Way.of.Water.2022.1080p.mkv"
        "Dune.2021.2160p.mkv"
    )
    
    for test in "${tests[@]}"; do
        echo "=== Testing: $test ==="
        torrent_parse "$test"
        echo ""
    done
}

# Run tests if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    test_analyzer
fi
