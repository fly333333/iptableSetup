**Concise IP's:**
- internet eth0
- internal (192.168.1.0/24) eth1
	- services:
		- database (192.168.1.100)
		- mail server (192.168.1.200)
- DMZ (10.0.0.0/24) eth2
	- DMZ public services:
		- web server (10.0.0.10)
		- FTP server (10.0.0.20)
**Input Chain:**

`sudo iptables -A INPUT -i eth0 -p tcp --dport 22 -m addrtype --dst-type LOCAL -s 198.51.100.1 -j ACCEPT`
- This allows 198.51.100.1 to access the firewall/router via SSH, from the internet (eth0) 

**Forward Chain:**
`sudo iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 80 -d 10.0.0.10 -j ACCEPT`
`sudo iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 443 -d 10.0.0.10 -j ACCEPT`
- These rules forward traffic from the internet (`eth0`) to the DMZ (`eth2`) if they are addressed to the webserver. It allows HTTP/S traffic.
`sudo iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 21 -d 10.0.0.20 -s 203.0.113.0/24 -j ACCEPT`
- These rules forward traffic from the internet (`eth0`) to the DMZ (`eth2`) if they are addressed to the ftp server.
```shell
for ip in $(cat /etc/iptables/smtp_whitelist.txt); do                            
     sudo iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 25 -d 192.168.1.200 -s $ip -j ACCEPT                     
 done 
```
- This for loop iterates through the smtp whitelist file, allowing all the provided ip's access from the internet (`eth0`) to the internal network (`eth1`). Specifically, the destination address is the mail server.
`sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT`
- Forward any internal traffic to the internet.
 `sudo iptables -A FORWARD -i eth2 -o eth0 -p udp --dport 53 -j ACCEPT`
 `sudo iptables -A FORWARD -i eth2 -o eth0 -p tcp --dport 53 -j ACCEPT`
 `sudo iptables -A FORWARD -i eth2 -o eth0 -p udp --dport 123 -j ACCEPT`
 - Forward any traffic from DMZ to the internet with the ports 53 and 123 (DNS, NTP).


**Output Chain:**
`sudo iptables -A OUTPUT -j ACCEPT`
- Accept any outgoing traffic from the firewall itself. 

**Logs and Drop:**                        
 `sudo iptables -A INPUT -j LOG --log-prefix "IPTables-Dropped: "`
` sudo iptables -A FORWARD -j LOG --log-prefix "IPTables-Dropped: "`
` sudo iptables -A OUTPUT -j LOG --log-prefix "IPTables-Dropped: " `
- Log all the non-accepted packets, that will then be dropped.
` sudo iptables -P INPUT DROP`
` sudo iptables -P FORWARD DROP`
- Drop all the packets not accepted. 

**Flags:**
- `-A` specifies the chain that will be used. `INPUT` in this case refers to all incoming traffic to the filtered table. 
- `-m` basically loads a an extra module you specify, for additional options
- `-m state` this module allows for the specification of a packet state, which tracks the sessions between both sides of communication. The available states include `INVALID`, `ESTABLISHED`, `NEW`, and `RELATED`. 
- `-j` What to do with the packet. In this case, we are accepting or logging it. There is also reject, drop, and log. 
- `-p` Refers to the protocol in use. Typically specifying udp/tcp, but can also do others such as icmp. We want tcp for this connection as http traffic is mostly using tcp.
- `--dport` Destination port. Can also specify the source port with `--sport`. Add an `s` to these to specify multiple ports (you would need to load the `multiport` module with `-m`)
- `-i` The receiving network interface (i.e. physical ports)
- `-o` The outbound network interface.
- `-m addrtype --dst-type` a module to specify the type of address, in this case the local address as the packets destination.
- `-s` source IP (or range with CIDR)
- `-d` destination ip (or range with CIDR)
