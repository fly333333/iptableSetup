
**GOAL**: allow incoming traffic on port 80 (HTTP) and port 443 (HTTPS), and outbound traffic from ports 53 and 123 (DNS, NTP), allow loopback (internal) traffic, log dropped packets, and then block everything else.

**INPUT Chain**
`sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT`
- Allows input with an established or related (established but new connection), and accepts them. 
`sudo iptables -A INPUT -i lo -j ACCEPT`
- Allows traffic from the input interface `lo`, which refers to internal loopback traffic on the machine. This is critical for allowing internal traffic, since the webserver in this situation is hosted locally. 
`sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT`
- Allow tcp traffic on port 80 (HTTP). For this goal, its not too big of a deal to ignore udp, as only Google's QUIC protocol or HTTP 1.3 uses it. So blocking it doesn't really inhibit any normal traffic. 
`sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT`
- Allow tcp traffic on port 443 (HTTPS). 
`sudo iptables -A INPUT -j LOG --log-prefix "Dropped INPUT Packets: "`
- Logs all the packets that aren't accepted by the rules above it (as long as they are dropped subsequently). Can query it using `sudo dmesg | grep "Dropped INPUT Packets:"`.
**OUTPUT Chain**
`sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT`
- The exact same as the `state` module command, just for the OUTPUT chain.
`sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT`
- Allow udp traffic on port 53 (DNS).
`sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT`
- Allow tcp traffic on port 53 (DNS). TCP is not totally necessary, though DNS uses TCP as a fallback in-case UDP is not working (e.g. packet size).
`sudo iptables -A OUTPUT -p udp --dport 123 -j ACCEPT`
- Allow udp traffic on port 123 (NTP).
`sudo iptables -A OUTPUT -j LOG --log-prefix "Dropped OUTPUT Packets: "`
- Same as the INPUT chain logging, just for the OUTPUT chain.

**Drop**
`sudo iptables -P INPUT DROP`
`sudo iptables -P OUTPUT DROP`
- Finish off with dropping any packets that are not accepted by the rules above.

**Flags**
- `-A` specifies the chain that will be used. `INPUT` in this case refers to all incoming traffic to the filtered table. 
- `-m` basically loads a an extra module you specify, for additional options
- `-m state` this module allows for the specification of a packet state, which tracks the sessions between both sides of communication. The available states include `INVALID`, `ESTABLISHED`, `NEW`, and `RELATED`. 
- `-j` What to do with the packet. In this case, we are accepting or logging it. There is also reject, drop, and log. 
- `-p` Refers to the protocol in use. Typically specifying udp/tcp, but can also do others such as icmp. We want tcp for this connection as http traffic is mostly using tcp.
- `--dport` Destination port. Can also specify the source port with `--sport`. Add an `s` to these to specify multiple ports (you would need to load the `multiport` module with `-m`)


