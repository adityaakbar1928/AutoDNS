#!/bin/bash

URL="https://trustpositif.kominfo.go.id/assets/db/domains_isp"
NEW_FILE="/tmp/new_domains_isp"
EXISTING_FILE="/var/named/rpz.zone"
HEADER_FILE="/tmp/header_file"

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if BIND/named is installed, if not install it
if ! command -v named &> /dev/null; then
    echo "BIND is not installed. Installing BIND..."
    yum install -y bind bind-utils
fi

# Define header content
cat <<EOF > "$HEADER_FILE"
\$TTL 1D
@       IN SOA  @ rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      @
        A       103.131.18.91
EOF

# Download the new file
wget "$URL" -O "$NEW_FILE" --no-check-certificate

# Get user input for IP to append
read -p "Enter the IP address to append: " IP_TO_APPEND

# Append the IP to the end of each line
sed -i "s/\$/ IN A $IP_TO_APPEND/" "$NEW_FILE"

# Prepend the header to the new file
cat "$HEADER_FILE" "$NEW_FILE" > "/tmp/temp_file" && mv "/tmp/temp_file" "$NEW_FILE"

# Check for differences
if diff "$NEW_FILE" "$EXISTING_FILE" >/dev/null ; then
    echo "No changes found."
else
    echo "Changes detected. Updating the existing file."
    mv "$NEW_FILE" "$EXISTING_FILE"
    # Reload the named service to apply changes
    systemctl reload named
fi

# Clean up the temporary header file
rm -f "$HEADER_FILE"

# Ensure permissions for rpz.zone
chmod 777 "$EXISTING_FILE"

# Configure named.conf
NAMED_CONF="/etc/named.conf"
cat <<EOF > "$NAMED_CONF"
options {
        listen-on port 53 { any; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        allow-query     { any; };
        response-policy { zone "rpz.zone"; };
        check-names master ignore;
        check-names slave ignore;
        recursion yes;
        dnssec-validation yes;
        managed-keys-directory "/var/named/dynamic";
        geoip-directory "/usr/share/GeoIP";
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
        include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

zone "rpz.zone" {
        type master;
        file "/var/named/rpz.zone";
        allow-query { any; };
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

# Ensure named service is enabled and started
systemctl enable named
systemctl start named
systemctl restart named

echo "Done"