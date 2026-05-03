#! /bin/bash

# Flush current rules
sudo iptables -F

# Input chain
# Internet To Webserver Allow:
sudo iptables -A INPUT -i eth0 -p tcp --dport 80 -d 10.0.0.10 -j ACCEPT
sudo iptables -A INPUT -i eth0 -p tcp --dport 443 -d 10.0.0.10 -j ACCEPT

# Internet (ip range 203.0.113.0/24) to FTP server Allow:
sudo iptables -A INPUT -i eth0 -p tcp -dport 21 -d 10.0.0.20 -s 203.0.113.0/24 -j ACCEPT

# Internet SSH (ip 198.51.100.1) to firewall/router server Allow:
sudo iptables -A INPUT -i eth0 -p tcp -dport 23 -m addrtype --dst-type LOCAL -s 203.0.113.0/24 -j ACCEPT

# Internet SMTP (from allowlist) to mail server Allow:
for ip in $(cat /etc/iptables/smtp_whitelist.txt); do
    sudo iptables -A INPUT -i eth0 -p tcp -dport 21 -d 192.168.1.200 -s $ip -j ACCEPT
done

# Output chain
# Block everything going out except:
sudo iptables -A OUTPUT -p udp --dport 53 -s 10.0.0.0/24 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -s 10.0.0.0/24 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 123 -s 10.0.0.0/24 -j ACCEPT
sudo iptables -A OUTPUT -s !192.168.1.0/24 -j ACCEPT

# Log dropped packets:
sudo iptables -A INPUT -j LOG --log-prefix "Dropped INPUT Packets: "
sudo iptables -A OUTPUT -j LOG --log-prefix "Dropped OUTPUT Packets: "

# Drop everything else
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
