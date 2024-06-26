#!/usr/bin/env bash
# Script to run ffuf on a list of targets in format https://targets.com. No ending "/" needed. Command ads it in.

targetlist=$1
wordlist=$2
wordlist_base=$(basename "$wordlist" .txt)
os_type=$(uname)

# Claen up any spaces in end of line for target list. Checking for os type to determine which sed command flavor to use.
if [[ "$os_type" == Darwin ]]; then
	sed -i '' 's/ $//g' ${targetlist}
else
	sed -i 's/ $//g' ${targetlist}
fi

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 targets.txt wordlist.txt"
	exit 1
fi

if [[ ! -f ${targetlist} ]]; then
	echo "Invalid target list. Please provide a text file, with one target per line"
	exit 1
fi

if [[ ! -f ${wordlist} ]]; then
	echo "Invalid wordlist list."
	exit 1
fi

echo ">[i] Starting to fuzz all targets"
echo ""

while IFS= read -r target; do
	hostname=$(echo "${target}" | awk -F/ '{print $3}')
	ffuf -c -u "${target}"/FUZZ -w $wordlist -of csv -o "${hostname}"_"${wordlist_base}".csv -ac
done <"${targetlist}"
