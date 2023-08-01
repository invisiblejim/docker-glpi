#!/bin/bash

#Controle du choix de version ou prise de la latest
[[ ! "$VERSION_GLPI" ]] \
	&& VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "TIMEZONE is unset"; 
else 
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/apache2/conf.d/timezone.ini;
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/cli/conf.d/timezone.ini;
fi

SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
TAR_GLPI=$(basename ${SRC_GLPI})
FOLDER_GLPI=glpi/
FOLDER_WEB=/var/www/html/glpi/public
FOLDER_CONFIG=/etc/glpi
FOLDER_DATA=/var/lib/glpi
FOLDER_LOGS=/var/log/glpi

#check if TLS_REQCERT is present
if !(grep -q "TLS_REQCERT" /etc/ldap/ldap.conf)
then
	echo "TLS_REQCERT isn't present"
    echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf
fi

#Download and Extract GLPI Source then add /inc/downstream.php to specify config directory outside of www-root
if [ "$(ls ${FOLDER_WEB}${FOLDER_GLPI})" ];
then
	echo "GLPI is already installed"
else
	wget -P ${FOLDER_WEB} ${SRC_GLPI}
	tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
	rm -Rf ${FOLDER_WEB}${TAR_GLPI}
	echo "<?php
	define('GLPI_CONFIG_DIR', '/etc/glpi/');
	if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
	require_once GLPI_CONFIG_DIR . '/local_define.php';
	}" >> ${FOLDER_WEB}${FOLDER_GLPI}/inc/downstream.php
	chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}
fi


# Check if config location contains data and if not add local_define.php to specify file data and log directories outside of www-root
if [ "$(ls ${FOLDER_CONFIG})" ];
then
	echo "GLPI Config already exists"
else
	echo "<?php
	define('GLPI_VAR_DIR', '/var/lib/glpi');
	define('GLPI_LOG_DIR', '/var/log/glpi');" >> ${FOLDER_CONFIG}/local_define.php
	chown -R www-data:www-data ${FOLDER_CONFIG}
fi

# Check if file location contains data and if not copy glpi/files
if [ "$(ls ${FOLDER_DATA})" ];
then
	echo "GLPI file Data already exists"
else
	cp -rp ${FOLDER_WEB}${FOLDER_GLPI}/files/. ${FOLDER_DATA}
	chown -R www-data:www-data ${FOLDER_DATA}
fi

# Check if log location contains data and if not set ownership
if [ "$(ls ${FOLDER_LOGS})" ];
then
	echo "GLPI Log Data already exists"
else
	chown -R www-data:www-data ${FOLDER_LOGS}
fi

#Modification du vhost par défaut
echo -e "<VirtualHost *:80>\n\tDocumentRoot /var/www/html/glpi\n\n\t<Directory /var/www/html/glpi>\n\t\tAllowOverride All\n\t\tOrder Allow,Deny\n\t\tAllow from all\n\t</Directory>\n\n\tErrorLog /var/log/apache2/error-glpi.log\n\tLogLevel warn\n\tCustomLog /var/log/apache2/access-glpi.log combined\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

#Add scheduled task by cron and enable
echo "*/2 * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" >> /etc/cron.d/glpi
#Start cron service
service cron start

#Activation du module rewrite d'apache
a2enmod rewrite && service apache2 restart && service apache2 stop

#Lancement du service apache au premier plan
/usr/sbin/apache2ctl -D FOREGROUND
