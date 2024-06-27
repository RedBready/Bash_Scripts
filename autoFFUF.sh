#!/usr/bin/env bash
# Script to run ffuf on a list of targets in format https://targets.com. No ending "/" needed. Command adds it in.
# For the last part that combines all csv files into ne xlsx, you need redcsv2xlsr. Install using "pipx install git+https://github.com/RedBready/redcsv2xlsx.git"

targetlist=$1
wordlist=$2
wordlist_base=$(basename "$wordlist" .txt)
os_type=$(uname)
useragent="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.6478.57 Safari/537.36"

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

# Claen up any spaces in end of line for target list. Checking for os type to determine which sed command flavor to use.
if [[ "$os_type" == Darwin ]]; then
	sed -i '' 's/ $//g' ${targetlist}
else
	sed -i 's/ $//g' ${targetlist}
fi

echo ">[i] Starting to fuzz all targets"
echo ""

while IFS= read -r target; do
	hostname=$(echo "${target}" | awk -F/ '{print $3}')
	ffuf -H "${useragent}" -c -u "${target}"/FUZZ -w $wordlist -of csv -o "${hostname}"_"${wordlist_base}".csv -ac
done <"${targetlist}"

if redcsv2xlsx "${wordlist_base}"_results.xlsx *"${wordlist_base}".csv; then
	rm *"${wordlist_base}.csv"
	echo ">[i] .csv files have been cleaned up."
else
	echo -e "\033[31m>[i]redcsv2xlsx failed. Is it installed?\033[0m"

fi
