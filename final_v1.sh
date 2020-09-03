#/bin/bash
#Debugging Mode
#set -xv

echo
echo  -e "\033[33;5;7m ========== SELF DIAGNOSE ========== \033[0m"
echo "This script gathers necessary information about the server running this script, check the server meets the requirements and report it to the user"
echo

#VARIABLE - Highlight text backround
bred="\e[41m\e[30m"
bgreen="\e[42m\e[30m"
bdef="\e[0m"

tblack='\e[30m'
#tdef='\e[39m'
tbold='\e[1m'
tnormal='\e[21m'
correct='\e[30m\e[42m'
tdef='\e[21m\e[39m\e[0m'

#FUNCTION FOR BLANK LINES
function blank2() {
for n in {1..2};
do echo;
done
}

echo "SCRIPT DETAILS"
echo "--------------"
echo "Name of the running script     : " $0
echo "Script process ID              : " $$
echo -n "Script run by root user?       :  " 
#CHECK SCRIPT RUN BY ROOT USER
if [ $(id -u) = 0 ]; then
 echo -e "[${bgreen}${tblack} Yes ${bdef}]"
else
 echo -e "[${bred} No ${bdef}]"
 echo "Terminating script"
 blank2
 sleep 3
 exit 2
fi
blank2

echo "CHECKING PACKAGE"
echo "----------------"
while IFS=" " read -r TYPE NAME
do
 if [ "$TYPE" = "package" ]; then
  printf 'Package %-22s: %s' $NAME
  dpkg -l | grep $NAME &>/dev/nul
   if [ $? -eq 0 ]; then
    echo -e "[ ${bgreen} Installed ${bdef} ]"
   else
    echo -e "[ ${bred} Not installed. ${bdef} ] Installing $NAME, please wait . . ."
    #apt update -y &>/dev/null &&
     apt install $NAME -y &>/dev/null
      if [ $? -eq 0 ]; then
     printf '%-35s....Installation Successful'
     echo
     echo
    #echo "Installed $NAME"
   else
    echo "Failed to install $NAME"
    fi
    fi
fi
done < service_program_list
blank2

echo "CHECKING SERVICE"
echo "----------------"
while IFS=" " read -r TYPE NAME
do
 if [ "$TYPE" = "service" ]; then
  printf 'Service %-22s: %s' $NAME
  SERVICE_ENABLE=$(systemctl is-enabled $NAME)
   if [ "$SERVICE_ENABLE" = "enabled" ]; then
    echo -ne "[ ${bgreen} Enabled ${bdef} "
   else
    echo -ne "[ ${bred} Disabled${bdef} "
   fi
  SERVICE_ACTIVE=$(systemctl is-active $NAME)
    if [ "$SERVICE_ACTIVE" = "active" ]; then
    echo -ne "${bgreen} Active  ${bdef} ] "
    echo
   else
    echo -ne "${bred} Inactive${bdef} ]"
    echo
   fi
fi
done < service_program_list
blank2

# IDENTIFYING SERVER (HOSTNAME, IP)
echo "IDENTIFYING SERVER"
echo "-------------------"
machine_ip=$(hostname -I | awk '{print $1}')
while IFS=" " read -r SRV_NAME SRV_IP
do
if [ "$machine_ip" = "$SRV_IP" ]; then
  echo "IP Address : " $SRV_IP
  echo "Server     : " $SRV_NAME
  SRV_FOUND="yes"
fi
done < server_list
if [ "$SRV_FOUND" != "yes" ]; then
 echo -e "${bred} ERROR ${bdef}: Currently logged in server is not listed in the server list file. Terminating script."
 blank2
 exit 1
fi
blank2

echo "SERVER INFO"
echo "-----------"
echo -n "Server type   : "
 dmidecode -t system | grep -i "Product name" | awk '{print $3}'
echo -n "Server uptime : "
 uptime -p
echo
echo "Currently logged on users"
echo "-------------------------"
w
blank2



# CHECK SERVER IS POINTING TO CORRECT TIMEZONE 
echo "TIME ZONE"
echo "---------"
echo -n "Time zone : " 
timedatectl | grep -i "universal time" | grep UTC
if [ $? -eq 0 ]; then 
 #echo -e "Time zone is ${bgreen}${tblack}CORRECT${tdef}${bdef}"
 echo -e "Time zone is [ ${correct} CORRECT ${tdef} ]"
else 
 echo -e "Time zone is [ ${bred} WRONG ${bdef} ]"
fi
blank2

#NETWORK SETAU=ILS
DEFAULT_GATEWAY=$(route -n | grep UG | awk '{print $2}')
MAC_ADDRESS=$(ifconfig -a | grep HWaddr | awk '{print $1 " - " $5}')
#EXTERNAL_IP=$(curl ifconfig.me &>/dev/nul)
EXTERNAL_IP=$(curl -s http://whatismyip.akamai.com)
EXTERNAL_IP_COUNTRY=$(curl -s https://ipvigilante.com/${EXTERNAL_IP} | jq '.data.city_name, .data.country_name')
NW_INTERFACE_FOR_INTERNET=$(ip route show | grep default | awk '{printf $5}')
DNS_SERVER=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')


echo "NETWORK ADAPTER INFO"
echo "--------------------"
echo -n "Total network adapter(s)   : "
ifconfig -a | grep 'Link encap' | awk '{print $1}' | wc -l
echo -n "Network adapter(s) name    : "
ifconfig -a | grep 'Link encap' | awk '{printf "%s ",$1}'
blank2

echo "Network adapter(s) status"
echo "-------------------------"
NETWORK_ADAPTERS=$(ifconfig -a | grep 'Link encap' | awk '{print $1}')
for NA_STATUS in $NETWORK_ADAPTERS
do
 printf 'Status of network adapter %-10s: %s'  "$NA_STATUS"
 ip link show | grep $NA_STATUS &>/dev/nul
 if [ $? -eq 0 ]; then
  echo -e "[${bgreen}${tblack} UP ${bdef}]"
 else
  echo -e "[${bred}${tblack} DOWN ${bdef}]"
 fi
done
blank2

echo "NETWORK INFO"
echo "------------"
echo    "Default gateway                   : " $DEFAULT_GATEWAY
echo    "MAC address                       : " $MAC_ADDRESS 
echo -n "External (Public) IP              : " $EXTERNAL_IP
echo 
echo    "External IP Location              : " $EXTERNAL_IP_COUNTRY  
echo    "Interface communicate to internet : " $NW_INTERFACE_FOR_INTERNET 
echo    "DNS server                        : " $DNS_SERVER
blank2 

#CHECKING IPs ARE REACHABLE
echo "CHECKING IPs ARE REACHABLE"
echo "-------------------------"
for PING_IP in $DEFAULT_GATEWAY $DNS_SERVER ubuntu.com
do
 printf 'Pinging %-15s: %s ' $PING_IP
 #echo -n "Pinging $PING_IP       : "
 ping -c 4 $PING_IP &>/dev/nul
 if [ $? -eq 0 ]; then
  echo -e "[${bgreen}${tblack} Yes ${bdef}]"
 else
  echo -e "[${bred}${tblack} No ${bdef}]"
 fi
done
blank2


echo "ACTIVE NETWORK CONNECTIONS"
echo "--------------------------"
netstat -tulpn
blank2




#SCRIPT FOOTER DETAILS

echo "Script execution time : $SECONDS seconds"
blank2
echo "==================== END OF SCRIPT ===================="
echo
