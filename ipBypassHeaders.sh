#!/usr/bin/env bash
# Bash Script that checks for authentication issues by fuzzing for common IP Bypass HTTP Headers

targets=$1
wordlist="./wordlists/ipBypassHeaderNameOnly.txt"
useragent="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.57 Safari/537.36"

if [[ ! -f $1 ]]; then
	echo "Usage: $0 urls.txt wordlists.txt"
	exit 1
fi

# Change the filter code (-fc) or regex (-fr) as needed based on how the tested API/Web App is responding.
while IFS= read -r url; do
	ffuf -c -u "${url}" -H "${useragent}" -H "FUZZ: 127.0.0.1" -w "${wordlist}" -v -fc 403 -fr "access denied"
done <"${targets}"
