#!/bin/bash
#urlfetchscriptbyxettabyte
set -e
bold="\e[1m"
version="0.1x"
red="\e[1;31m"
green="\e[32m"
blue="\e[34m"
cyan="\e[0;36m"
end="\e[0m"
#bannner
clear
echo -e "\n\n"

echo -e "${green}█▀▀ █▀█ ▄▀█ █░█░█ █░░ █▀▀ █▀█ █▀▀ █▀█ █▀█ █░█░█ "
echo -e "█▄▄ █▀▄ █▀█ ▀▄▀▄▀ █▄▄ ██▄ █▀▄ █▄▄ █▀▄ █▄█ ▀▄▀▄▀ ${end}"
echo -e "                      ${bold}made with ❤️ by ${red}xettabyte!${end}"
urlname=${1::-4}urls
printf "\n\n\n"
printf "${cyan}TIP:Enter your Doamain list as first argument ,this script will fetch all available Endpoints with Parameter${end}"


#WAYBACKURLS
echo -e "\n\n\n[#]${blue}Using Waybackurls for gathering Urls for ${red}$1 .......${end}"| pv -qL $[20+(-2 + RANDOM%5)]
cat "$1" | waybackurls | tee "$urlname".txt >/dev/null 2>&1;
echo "Wayback Done for $urlname " | notify -silent >/dev/null 2>&1;
printf "\n\n[#]${blue}URLS fetched using waybackurls & Stored in ${red}${bold}$urlname.txt${end}" | pv -qL $[10+(-2 + RANDOM%5)]

#GAU
printf "\n\n[#]${blue}Using Gau for getting urls for${end}${red} $1 \n" | pv -qL $[15+(-2 + RANDOM%5)]
cat "$1" | gau | tee gau.txt >/dev/null 2>&1;
echo "Gau Done for $urlname " | notify -silent >/dev/null 2>&1;
printf "\n\n[#]${blue}URLS fetched using gau & appended in ${red}${bold}$urlname.txt${end} \n\n" |  pv -qL $[15+(-2 + RANDOM%5)]
# Sorting Out them
sort -u $urlname.txt gau.txt > fetchedurls.txt ;


#filteration

# cat $urlname.txt | anew gau.txt > filterd.txt>/dev/null 2>&1;
# printf "\n\n[#]${red}Used ANEW for Removing Dupliacates" |  pv -qL $[10+(-2 + RANDOM%5)]
# printf "\n\n[#]Sending results to URO for  filter out it again" | pv -qL $[16+(-2 + RANDOM%5)]
# cat $urlname.txt | uro |tee fetchedurls.txt >/dev/null 2>&1;


#removing tempfiles

printf "\n\n[#]${cyan}Removing Temporary files " | pv -qL $[10+(-2 + RANDOM%5)]
rm gau.txt
rm $urlname.txt
echo -e "\n\n[#]${red}🎯Done :(${end}" |  pv -qL $[10+(-2 + RANDOM%5)]

urlcount=$(cat fetchedurls.txt | wc -l)
echo -e "\n\n[#]${cyan} ✔️ Total ${red}${urlcount} URls Fetched"


echo -e "\n\n[#]📝Results are saved in ${red}fetchedurls.txt" | pv -qL $[10+(-2 + RANDOM%5)]
echo -e "\n\n[#]Good luck 🤞" |  pv -qL $[10+(-2 + RANDOM%5)]
echo "url fetched for $urlname " | notify -silent >/dev/null 2>&1;

#GOSPIDER
# printf "\n\n[+]Using Gospider for getting urls for $1 \n"
# gospider -S $1 -o urlname -c 10 -d 1 -t 20 >/dev/null 2>&1;
# printf "\n\nURLS fetched using gau & appended in $red$bold$urlname.txt$end \n\n"
