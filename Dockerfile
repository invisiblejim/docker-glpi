#On choisit une debian
FROM debian:11.8

LABEL org.opencontainers.image.authors="github@diouxx.be"


#Ne pas poser de question à l'installation
ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt install -y wget gnupg2 lsb-release
RUN wget https://packages.sury.org/php/apt.gpg && apt-key add apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

#Installation d'apache et de php8.1 avec extension
RUN apt update \
&& apt install --yes --no-install-recommends \
apache2 \
php8.1 \
php8.1-mysql \
php8.1-ldap \
php8.1-xmlrpc \
php8.1-imap \
curl \
php8.1-curl \
php8.1-fileinfo \
php8.1-gd \
php8.1-mbstring \
php8.1-simplexml \
php8.1-xml \
php-cas \
php8.1-intl \
php8.1-cli \
php8.1-zip \
php8.1-bz2 \
php8.1-redis \
cron \
wget \
ca-certificates \
jq \
libldap-2.4-2 \
libldap-common \
libsasl2-2 \
libsasl2-modules \
libsasl2-modules-db \
&& rm -rf /var/lib/apt/lists/*

#Copie et execution du script pour l'installation et l'initialisation de GLPI
COPY glpi-start.sh /opt/
RUN chmod +x /opt/glpi-start.sh
ENTRYPOINT ["/opt/glpi-start.sh"]

#Exposition des ports
EXPOSE 80 443
