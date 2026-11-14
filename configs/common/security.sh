#!/bin/sh
# Shared security policy for site routers.
#  - Guests: internet + DNS/DHCP only, no internal access
#  - Management: SSH only, from mgmt VLANs / lab mgmt network
set -e
: "${SITE_GUEST:?SITE_GUEST must be set}"

# ---------- Guest isolation (FORWARD chain = traffic through the router) ----------
iptables -N GUEST-ACL 2>/dev/null || iptables -F GUEST-ACL
iptables -A GUEST-ACL -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A GUEST-ACL -d 10.10.20.10 -p udp --dport 53 -j ACCEPT   # DNS on hq-srv1
iptables -A GUEST-ACL -d 10.10.20.10 -p tcp --dport 53 -j ACCEPT
iptables -A GUEST-ACL -d 10.0.0.0/8 -j LOG --log-prefix "GUEST-DENY " --log-level 4
iptables -A GUEST-ACL -d 10.0.0.0/8 -j DROP                        # all internal
iptables -A GUEST-ACL -j ACCEPT                                    # internet
iptables -I FORWARD -s "$SITE_GUEST" -j GUEST-ACL

# ---------- Management plane: SSH only, from trusted subnets ----------
adduser -D -s /bin/sh netadmin 2>/dev/null || true
echo "netadmin:${NETADMIN_PASS:-Lab@dmin123}" | chpasswd
addgroup netadmin frrvty 2>/dev/null || true
ssh-keygen -A >/dev/null
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
/usr/sbin/sshd

iptables -N MGMT-IN 2>/dev/null || iptables -F MGMT-IN
iptables -A MGMT-IN -s 10.10.99.0/24 -j ACCEPT
iptables -A MGMT-IN -s 10.20.99.0/24 -j ACCEPT
iptables -A MGMT-IN -s 172.20.20.0/24 -j ACCEPT    # lab automation host
iptables -A MGMT-IN -j LOG --log-prefix "SSH-DENY " --log-level 4
iptables -A MGMT-IN -j DROP
iptables -I INPUT -p tcp --dport 22 -j MGMT-IN
# No telnet / no vtysh over TCP from outside
iptables -I INPUT -p tcp --dport 23 -j DROP
iptables -I INPUT -p tcp --dport 2601:2610 ! -s 127.0.0.1 -j DROP
