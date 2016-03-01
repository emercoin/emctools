#!/bin/bash
# Emercoin Web Wallet for Ubuntu
# Deps: Emercoind, EMCSSH

if [ `whoami` != 'root' ]; then echo "Run me as root"; exit 1; fi
if [ ! -x /usr/local/bin/emercoind ]; then echo "Emercoind not found"; exit 1; fi
if [ ! -f /var/lib/emc/.emercoin/emercoin.conf ]; then echo "Emercoind not configured"; exit 1; fi
if [ ! -x /usr/local/sbin/emcssh ]; then echo "EMCSSH not found"; exit 1; fi
if [ ! -d /usr/local/etc/emcssh_keys ]; then echo "EMCSSH not configured"; exit 1; fi
getent passwd emc >/dev/null || { echo "User 'emc' not found"; exit 1; }

apt-get -y install git pwgen python-dev python-pip apache2 libapache2-mod-wsgi
pip install --upgrade pip
pip install Flask
pip install peewee
a2enmod ssl
a2enmod rewrite

touch /usr/local/etc/emcssh_keys/emcweb

cd /var/lib
git clone https://github.com/Emercoin/emcweb

cat<<EOF >/var/lib/emcweb/config/rpc
{
    "user": "emccoinrpc",
    "password": "`grep rpcpassword /var/lib/emc/.emercoin/emercoin.conf | sed 's/rpcpassword=//'`",
    "host": "127.0.0.1",
    "port": "6662"
}
EOF

chown -R emc.emc /var/lib/emcweb
sed -i -e "s/gf6dfg87sfg7sf5gs4dfg5s7fgsd980n/`pwgen 30 1`/" /var/lib/emcweb/server.py
cp -f /var/lib/emcweb/emcssl_ca.crt /etc/ssl/certs/emcssl_ca.crt
cp -f /var/lib/emcweb/emcweb.apache2.conf /etc/apache2/sites-available/emcweb.conf
ln -s /etc/apache2/sites-available/emcweb.conf /etc/apache2/sites-enabled/emcweb.conf
rm -f /etc/apache2/sites-enabled/default-ssl.conf

service apache2 restart
