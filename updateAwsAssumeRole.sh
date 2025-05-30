# This bash script runs `aws sts assume-role` with the provided role ARN and session name,
# then adds a new profile to ~/.aws/credentials with the returned credentials.

set -euo pipefail

# Define color codes
RED='\033[0;31m'
NC='\033[0m' # No Color

# Usage: ./this_script.sh -r <role-arn> -s <session-name> [-p profile_name] [-R region]
# Example: ./this_script.sh -r arn:aws:iam::123456789012:role/myrole -s mysession -p myprofile -R us-west-2

# Parse command line arguments
while getopts "r:s:p:R:" opt; do
  case $opt in
  r) ROLE_ARN="$OPTARG" ;;
  s) SESSION_NAME="$OPTARG" ;;
  p) PROFILE_NAME="$OPTARG" ;;
  R) REGION="$OPTARG" ;;
  \?)
    echo "${RED}Error: Invalid option -$OPTARG${NC}" >&2
    exit 1
    ;;
  esac
done

# Check required parameters
if [[ -z "${ROLE_ARN:-}" || -z "${SESSION_NAME:-}" ]]; then
  echo "${RED}Error: Missing required parameters${NC}" >&2
  echo "Usage: $0 -r <role-arn> -s <session-name> [-p profile_name] [-R region]" >&2
  exit 1
fi

# Set defaults for optional parameters
PROFILE_NAME="${PROFILE_NAME:-assumed-$SESSION_NAME}"
REGION="${REGION:-}"

# Validate region if provided
if [[ -n "$REGION" ]]; then
  # List of valid AWS regions
  valid_regions=(
    "us-east-1" "us-east-2" "us-west-1" "us-west-2"
    "af-south-1" "ap-east-1" "ap-south-1" "ap-northeast-1"
    "ap-northeast-2" "ap-northeast-3" "ap-southeast-1"
    "ap-southeast-2" "ap-southeast-3" "ca-central-1"
    "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3"
    "eu-north-1" "eu-south-1" "me-south-1" "sa-east-1"
  )

  is_valid=0
  for valid_region in "${valid_regions[@]}"; do
    if [[ "$REGION" == "$valid_region" ]]; then
      is_valid=1
      break
    fi
  done

  if [[ $is_valid -eq 0 ]]; then
    echo "${RED}Error: Invalid AWS region '$REGION'${NC}" >&2
    echo "Valid regions are: ${valid_regions[*]}" >&2
    exit 1
  fi
fi

# Call aws sts assume-role
ASSUME_OUTPUT=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "$SESSION_NAME")

# Extract values using jq
ACCESS_KEY=$(echo "$ASSUME_OUTPUT" | jq -r '.Credentials.AccessKeyId')
SECRET_KEY=$(echo "$ASSUME_OUTPUT" | jq -r '.Credentials.SecretAccessKey')
SESSION_TOKEN=$(echo "$ASSUME_OUTPUT" | jq -r '.Credentials.SessionToken')

if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" || -z "$SESSION_TOKEN" ]]; then
  echo "${RED}Error: Failed to retrieve credentials from assume-role output${NC}" >&2
  exit 1
fi

CREDENTIALS_FILE="${HOME}/.aws/credentials"

# Backup credentials file
cp "$CREDENTIALS_FILE" "${CREDENTIALS_FILE}.bak.$(date +%s)" 2>/dev/null || true

# Remove existing profile if present
awk -v profile="[$PROFILE_NAME]" '
    BEGIN {skip=0}
    $0 ~ /^\[.*\]$/ {skip=($0==profile)}
    !skip
' "$CREDENTIALS_FILE" 2>/dev/null >"${CREDENTIALS_FILE}.tmp" || true

# Append new profile
{
  echo ""
  echo "[$PROFILE_NAME]"
  echo "aws_access_key_id = $ACCESS_KEY"
  echo "aws_secret_access_key = $SECRET_KEY"
  echo "aws_session_token = $SESSION_TOKEN"
  if [[ -n "$REGION" ]]; then
    echo "region = $REGION"
  fi
} >>"${CREDENTIALS_FILE}.tmp"

# Move temp file to credentials file
mv "${CREDENTIALS_FILE}.tmp" "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE"

echo "Added profile [$PROFILE_NAME] to $CREDENTIALS_FILE"
