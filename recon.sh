# Automated Website OSINT for Kali
# Requires whois, subfinder, assetfinder, httprobe, and gowitness

#!/bin/bash

set -e

# Use the first argument as the domain name
domain=$1

# Exit if no domain is provided
if [ -z "$domain" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

# Define colors
RED="\033[1;31m"
RESET="\033[0m"

# Define directories
base_dir="$domain"
info_path="$base_dir/info"
subdomain_path="$base_dir/subdomains"
screenshot_path="$base_dir/screenshots"
log_file="$base_dir/recon.log"

# Check if necessary tools are installed
for cmd in whois subfinder assetfinder httprobe gowitness; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}[!] $cmd not found! Please install it and try again.${RESET}"
        exit 1
    fi
done

# Create directories if they don't exist
for path in "$info_path" "$subdomain_path" "$screenshot_path"; do
    if [ ! -d "$path" ]; then
        mkdir -p "$path" || { echo "Failed to create directory $path"; exit 1; }
        echo "Created directory: $path"
    fi
done

# Log start
echo "$(date) - Started recon for $domain" >> "$log_file"

echo -e "${RED}[+] Checking whois info...${RESET}"
whois "$domain" | grep -E 'Domain|Registrar|Updated|Creation' > "$info_path/whois.txt"

echo -e "${RED}[+] Launching Subfinder...${RESET}"
subfinder -d "$domain" -silent > "$subdomain_path/found.txt"

echo -e "${RED}[+] Running Assetfinder...${RESET}"
assetfinder "$domain" | grep "$domain" >> "$subdomain_path/found.txt"

echo -e "${RED}[+] Checking what's alive...${RESET}"
grep "$domain" "$subdomain_path/found.txt" | sort -u | \
httprobe -prefer-https | grep https > "$subdomain_path/alive.txt"

echo -e "${RED}[+] Taking screenshots with Gowitness...${RESET}"
gowitness scan file -f "$subdomain_path/alive.txt" -s "$screenshot_path" --no-http

# Clean up temporary files
rm "$subdomain_path/found.txt"

# Log end
echo "$(date) - Recon completed for $domain" >> "$log_file"
