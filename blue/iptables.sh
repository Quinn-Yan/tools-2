#!/usr/bin/env bash
#set path of iptables
path=/sbin
#shitboxIP=10.0.0.0
#scoremaster=10.0.0.0

#drop all previous rules
$path/iptables -F
$path/ip6tables -F

#block typical bad stuff
$path/iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP #null packets
$path/iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP #syn-flood packets
$path/iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP #XMAS packets (recon)
$path/iptables -A INPUT -m state --state INVALID -j DROP #invalid packets

# Accept in/out from loopback
$path/iptables -A INPUT -i lo -j ACCEPT
$path/iptables -A OUTPUT -o lo -j ACCEPT

# Allow icmp request/reply from and to host
$path/iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT
$path/iptables -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
$path/iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
$path/iptables -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT

# Allow established TCP connections to re-enter
$path/iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT

# Allow HTTP and HTTPS in and out for server and client
$path/iptables -A OUTPUT -p tcp -m multiport --sports 80,443 -j ACCEPT #server outbound
$path/iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT #server inbound
$path/iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -j ACCEPT #client outbound
#$path/iptables -A INPUT -p tcp -m multiport --sports 80,443 -j ACCEPT #client inbound - shouldn't need as long as you allow established tcp connections back in

# Allow MySQL queries as a client
#$path/iptables -A INPUT -p tcp -m tcp --sport 3306 -j ACCEPT
#$path/iptables -A OUTPUT -p tcp -m tcp --dport 3306 -j ACCEPT

# Allow MySQL queries as a server
#$path/iptables -A INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
#$path/iptables -A OUPUT -p tcp -m tcp --sport 3306 -j ACCEPT

# Allow DNS queries as a client
$path/iptables -A INPUT -p udp --sport 53 -j ACCEPT
$path/iptables -A INPUT -p tcp --sport 53 -j ACCEPT #needed for large zone transfers
$path/iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
$path/iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT #needed for large zone transfers

#allow DNS queries as a server
#$path/iptables -A INPUT -p udp --dport 53 -j ACCEPT
#$path/iptables -A INPUT -p tcp --dport 53 -j ACCEPT #needed for large zone transfers
#$path/iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
#$path/iptables -A OUTPUT -p tcp -m tcp --sport 53 -j ACCEPT #needed for large zone transfers

# Allow DHCP client traffic
#$path/iptables -A INPUT -p udp --dport 68 -j ACCEPT
#$path/iptables -A OUTPUT -p udp --sport 68 -j ACCEPT

# Allow DHCP server traffic
#$path/iptables -A INPUT -p udp --dport 67 -j ACCEPT
#$path/iptables -A OUTPUT -p udp --sport 67 -j ACCEPT

#allow ssh in and out for a server
#$path/iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
#$path/iptables -A OUTPUT -p tcp -m tcp --sport 22 -j ACCEPT

#allow ssh out for a client
$path/iptables -A INPUT -p tcp -m tcp --sport 22 -j ACCEPT
$path/iptables -A OUTPUT -p tcp -m tcp --dport 22 -j ACCEPT

#allow FTP server traffic; only for ftp servers!
#$path/iptables -A INPUT -p tcp -m tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT #initial connection
#$path/iptables -A OUTPUT -p tcp -m tcp --sport 21 -m state --state NEW,ESTABLISHED -j ACCEPT #initial connection
#$path/iptables -A INPUT -p tcp -m tcp --dport 20 -m state --state NEW,ESTABLISHED -j ACCEPT #active mode
#$path/iptables -A OUTPUT -p tcp -m tcp --sport 20 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT #active mode
#$path/iptables -A INPUT -p tcp -m tcp --sport 1024:65535 --dport 1024:65535 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT #passive
#$path/iptables -A OUTPUT -p tcp -m tcp --sport 1024:65535 --dport 1024:65535 -m state --state NEW,ESTABLISHED -j ACCEPT #passive

#smtp in/out rules; only for smtp servers!
#$path/iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
#$path/iptables -A OUTPUT -p tcp -m tcp --sport 25 -j ACCEPT

#allow opsview agent in/out to specific IP address (if using monitoring service)
#monServer=127.0.0.1 #<-replace with IP of monitoring server
#$path/iptables -A INPUT -p tcp -s $monServer --dport 5666 -j ACCEPT
#$path/iptables -A OUTPUT -p tcp -d $monServer --sport 5666 -j ACCEPT

#TODO, rules for POP and/or IMAP

#VOIP - needed for asterisk/voip server!
# SIP on UDP port 5060. Other SIP servers may need TCP port 5060 as well
#$path/iptables -A INPUT -p udp -m udp --dport 5060 -j ACCEPT
#$path/iptables -A INPUT -p udp -m udp --dport 4569 -j ACCEPT # IAX2- the IAX protocol
#$path/iptables -A INPUT -p udp -m udp --dport 5036 -j ACCEPT # IAX - most have switched to IAX v2, or ought to
 # RTP - the media stream
#$path/iptables -A INPUT -p udp -m udp --dport 10000:20000 -j ACCEPT # (related to the port range in /etc/asterisk/rtp.conf)
#$path/iptables -A INPUT -p udp -m udp --dport 2727 -j ACCEPT # MGCP - if you use media gateway control protocol in your configuration

# Log firewall hits
$path/iptables -A INPUT -m limit --limit 15/min -j LOG --log-level 4 --log-prefix "INv4 "
$path/iptables -A OUTPUT -m limit --limit 15/min -j LOG --log-level 4 --log-prefix "OUTv4 "
$path/ip6tables -A INPUT -m limit --limit 3/min -j LOG --log-level 4 --log-prefix "INv6 "
$path/ip6tables -A OUTPUT -m limit --limit 3/min -j LOG --log-level 4 --log-prefix "OUTv6 "

# Drop all other stuff
$path/iptables -A INPUT -j DROP
$path/iptables -A OUTPUT -j DROP
$path/ip6tables -A INPUT -j DROP
$path/ip6tables -A OUTPUT -j DROP

# INSTATE THESE RULES ON HOST TO PROTECT
# This will reroute non-scoring engine traffic to a honeypot and allow the traffic to be routed back from
# that honeypot to the original sender.
# NOTE: vsftpd needs pasv_promiscuous=yes for "fake" ftp

# echo "1" > /proc/sys/net/ipv4/ip_forward
# $path/iptables -D INPUT -j DROP
# $path/iptables -D OUTPUT -j DROP
# $path/iptables -t nat -A PREROUTING -p tcp -j DNAT --to-destination $shitboxIP #Make all traffic go to the playground
# $path/iptables -t nat -A POSTROUTING -d $shitboxIP -p tcp -j MASQUERADE
# $path/iptables -t nat -I PREROUTING -p tcp -s $scoremaster -j ACCEPT #Accept all traffic from the scorebox

# $path/iptables -t nat -A PREROUTING -p udp -j DNAT --to-destination $shitboxIP #Make all traffic go to the playground
# $path/iptables -t nat -A POSTROUTING -d $shitboxIP -p udp -j MASQUERADE
# $path/iptables -t nat -I PREROUTING -p udp -s $scoremaster -j ACCEPT #Accept all traffic from the scorebox

#$path/iptables -I INPUT -d $shitboxIP -j ACCEPT
#$path/iptables -I FORWARD -d $shitboxIP -j ACCEPT
#$path/iptables -I OUTPUT -d $shitboxIP -j ACCEPT
#$path/iptables -I INPUT -s $shitboxIP -j ACCEPT
#$path/iptables -I FORWARD -s $shitboxIP -j ACCEPT
#$path/iptables -I OUTPUT -s $shitboxIP -j ACCEPT

