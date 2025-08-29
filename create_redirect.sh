#!/bin/bash
# This script creates an Apache virtual host that redirects from one domain to another,
# and obtains an SSL certificate via certbot.
#
# The script must be run with root privileges!
#
# Usage: ./create_redirect.sh oldsite.com newsite.com

if [ $# -ne 2 ]; then
  echo "Usage: $0 source-domain.com target-domain.com"
  exit 1
fi

SOURCE=$1
TARGET=$2
APACHE_CONF="/etc/apache2/sites-available/$SOURCE.conf"

# Create Apache vhost config with redirect
cat > $APACHE_CONF <<EOF
<VirtualHost *:80>
    ServerName $SOURCE
    ServerAlias www.$SOURCE

    # Permanent redirect to target domain
    Redirect permanent / https://$TARGET/

    ErrorLog \${APACHE_LOG_DIR}/$SOURCE-error.log
    CustomLog \${APACHE_LOG_DIR}/$SOURCE-access.log combined
</VirtualHost>
EOF

# Enable site & reload Apache
a2ensite $SOURCE.conf
systemctl reload apache2

# Enable SSL + get certificate for redirect domain
if ! command -v certbot >/dev/null 2>&1; then
  echo "Certbot not found. Installing..."
  apt update && apt install -y certbot python3-certbot-apache
fi

certbot --apache -d $SOURCE -d www.$SOURCE --redirect

echo "Done! $SOURCE is now redirecting to $TARGET"
