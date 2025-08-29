#!/bin/bash
# This script creates an Apache virtual host for a given domain,
# sets up the web root, and obtains an SSL certificate via certbot.
#
# The script must be run with root privileges!
#
# Usage: ./create_vhost.sh example.com

if [ -z "$1" ]; then
  echo "Usage: $0 domain.com"
  exit 1
fi

DOMAIN=$1
WEBROOT="/var/www/$DOMAIN"
APACHE_CONF="/etc/apache2/sites-available/$DOMAIN.conf"

# Create web root directory
mkdir -p $WEBROOT
chown -R www-data:www-data $WEBROOT
chmod -R 755 $WEBROOT

# Add a simple index.html
echo "<h1>Welcome to $DOMAIN</h1>" > $WEBROOT/index.html

# Create Apache vhost file
cat > $APACHE_CONF <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot $WEBROOT

    <Directory $WEBROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOF

# Enable site & reload Apache
a2ensite $DOMAIN.conf
systemctl reload apache2

# Enable required Apache modules
a2enmod rewrite ssl

# Obtain SSL certificate via certbot
if ! command -v certbot >/dev/null 2>&1; then
  echo "Certbot not found. Installing..."
  apt update && apt install -y certbot python3-certbot-apache
fi

certbot --apache -d $DOMAIN -d www.$DOMAIN --redirect

echo "Done! Your site is available at https://$DOMAIN/"
