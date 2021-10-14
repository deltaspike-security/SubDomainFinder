#!/bin/bash

#The script will automates following tasks:
#1.searching subdomains using search engines
#2.searchinng subdomains using bruteforcing with sublist3r/subbrute default wordlist
#3.compare the 2 lists and show subdomains that are found only using bruteforcing
#4.trying to connect to each subdomain and estabilish if they are accessible or not
#5.make a list of all active found subdomains URLS to import to ZAP/burp suite
#The subdomains list for bruteforcing is the one used by subbrute (names.txt)

#USAGE script.sh <domain>

#NO BRUTE
mkdir -p /tmp/SubdomFAndT
sublist3r -d $1 -o /tmp/SubdomFAndT/sublist3r_out_nobrute
cat /tmp/SubdomFAndT/sublist3r_out_nobrute | sed 's/<BR>/\n/g' | sort -u > /tmp/SubdomFAndT/subs_nobrute.txt

echo RESULTS FROM SEARCH ENGINES: | tee /tmp/SubdomFAndT/results_nobrute.txt
for obj in $(cat /tmp/SubdomFAndT/subs_nobrute.txt); do
	testHTTPS=$(curl -s https://$obj --head --connect-timeout 15 | grep HTTP/)
	testHTTP=$(curl -s http://$obj --head --connect-timeout 15 | grep HTTP/)
	if [ -z "$testHTTPS" ];
		then
			echo [-] https://$obj "CAN'T CONNECT WITH HTTPS" | tee -a /tmp/SubdomFAndT/results_nobrute.txt
		else	
			echo [+]  "https://"$obj  $testHTTP | tee -a /tmp/SubdomFAndT/results_nobrute.txt
	fi
	if [ -z "$testHTTP" ] ;
		then
			echo [-] http://$obj "CAN'T CONNECT WITH HTTP" | tee -a /tmp/SubdomFAndT/results_nobrute.txt
		else
			echo [+] "http://"$obj  $testHTTP | tee -a /tmp/SubdomFAndT/results_nobrute.txt
	fi
done

echo ACTIVE SUBDOMAINS FROM SEARCH ENGINES:
cat /tmp/SubdomFAndT/results_nobrute.txt | grep + | cut -d " " -f2-7 >/tmp/SubdomFAndT/nobrute_urlslist.txt


#BRUTE
sublist3r -d $1 -b -o /tmp/SubdomFAndT/sublist3r_out_brute
cat /tmp/SubdomFAndT/sublist3r_out_brute | sed 's/<BR>/\n/g' | sort -u > /tmp/SubdomFAndT/subs_brute.txt
comm -13 /tmp/SubdomFAndT/subs_nobrute.txt /tmp/SubdomFAndT/subs_brute.txt > /tmp/SubdomFAndT/subs_diff.txt

echo RESULTS FROM BRUTEFORCING: | tee /tmp/SubdomFAndT/results_diff.txt
for obj in $(cat /tmp/SubdomFAndT/subs_diff.txt); do
	testHTTPS=$(curl -s https://$obj --head --connect-timeout 15 | grep HTTP/)
	testHTTP=$(curl -s http://$obj --head --connect-timeout 15 | grep HTTP/)
	if [ -z "$testHTTPS" ];
	then
		echo [-] https://$obj "CAN'T CONNECT WITH HTTPS" | tee -a /tmp/SubdomFAndT/results_diff.txt
	else	
		echo [+]  "https://"$obj  $testHTTP | tee -a /tmp/SubdomFAndT/results_diff.txt
	fi
	if [ -z "$testHTTP" ] ;
		then
			echo [-] http://$obj "CAN'T CONNECT WITH HTTP" | tee -a /tmp/SubdomFAndT/results_diff.txt
		else
			echo [+] "http://"$obj  $testHTTP | tee -a /tmp/SubdomFAndT/results_diff.txt
	fi
done
echo ACTIVE SUBDOMAINS FROM BRUEFORCING:
cat /tmp/SubdomFAndT/results_diff.txt | grep + | cut -d " " -f2-7 > /tmp/SubdomFAndT/brute_urllist.txt

#Writing ACTIVE URLS to a new file

sort /tmp/SubdomFAndT/nobrute_urlslist.txt /tmp/SubdomFAndT/brute_urllist.txt | cut -d " " -f2 > FinalUrl_list.txt




