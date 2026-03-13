# Dans ton chroot.sh

# 1. On écrit la config complète d'un coup
cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        iif lo accept
        ct state established,related accept

        # Ports Brother (Impression + Scan + Discovery)
        udp dport 5353 accept
        tcp dport 631 accept
        udp dport 54925 accept
        tcp dport 54921 accept
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

# 2. On dit au système de charger ça à chaque boot
systemctl enable nftables