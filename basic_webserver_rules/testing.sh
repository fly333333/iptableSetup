#!/bin/bash

# reset existing rules
sudo iptables -F

# filtered table (default), INPUT chain
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -j LOG --log-prefix "Dropped INPUT Packets: "

# filtered table (default), OUTPUT chain
sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 123 -j ACCEPT
sudo iptables -A OUTPUT -j LOG --log-prefix "Dropped OUTPUT Packets: "

# Drop everything else for both chains.
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
