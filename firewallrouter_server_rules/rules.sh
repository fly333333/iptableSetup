#! /bin/bash

# Flush current rules
sudo iptables -F

# Input chain
# loopback
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Internet SSH (ip 198.51.100.1) to firewall/router server Allow:
sudo iptables -A INPUT -i eth0 -p tcp --dport 22 -m addrtype --dst-type LOCAL -s 198.51.100.1 -j ACCEPT

# Forward chain
# loopback
sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Internet To Webserver Allow:
sudo iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 80 -d 10.0.0.10 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 443 -d 10.0.0.10 -j ACCEPT

# Internet (ip range 203.0.113.0/24) to FTP server Allow:
sudo iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 21 -d 10.0.0.20 -s 203.0.113.0/24 -j ACCEPT

# Internet SMTP (from allowlist) to mail server Allow:
for ip in $(cat /etc/iptables/smtp_whitelist.txt); do
    sudo iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 25 -d 192.168.1.200 -s $ip -j ACCEPT
done

# Output chain
# loopback
sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# all outgoing from firewall/router itself allow:
sudo iptables -A OUTPUT -j ACCEPT

# Allow internal network outgoing (with forward and interfaces, rather that output):
sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

# DMZ DNS and NTP outgoing allow:
sudo iptables -A FORWARD -i eth2 -o eth0 -p udp --dport 53 -j ACCEPT
sudo iptables -A FORWARD -i eth2 -o eth0 -p tcp --dport 53 -j ACCEPT
sudo iptables -A FORWARD -i eth2 -o eth0 -p udp --dport 123 -j ACCEPT

# Log dropped packets:
sudo iptables -A INPUT -j LOG --log-prefix "IPTables-Dropped: "
sudo iptables -A FORWARD -j LOG --log-prefix "IPTables-Dropped: "
sudo iptables -A OUTPUT -j LOG --log-prefix "IPTables-Dropped: "
# Drop everything else
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP
