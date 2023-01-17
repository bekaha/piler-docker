#!/bin/bash

# Colors
if [ -z ${BASH_SOURCE} ]; then
	blue=`echo "\e[1m\e[34m"`
	green=`echo "\e[1m\e[32m"`
	greenBold=`echo "\e[1m\e[1;32m"`
	redBold=`echo "\e[1m\e[1;31m"`
	red=`echo "\e[1m\e[31m"`
	purple=`echo "\e[1m\e[35m"`
	bold=`echo "\e[1m"`
  	normal=`echo "\e[0m"`
else
  	blue=`echo -e "\e[1m\e[34m"`
  	green=`echo -e "\e[1m\e[32m"`
  	greenBold=`echo -e "\e[1m\e[1;32m"`
	redBold=`echo -e "\e[1m\e[1;31m"`
	puple=`echo -e "\e[1m\e[35m"`
	bold=`echo -e "\e[1m"`
  	normal=`echo -en "\e[0m"`
fi

HLINE="=================================================================="

BLA_metro=( 0.2 '    ' '=   ' '==  ' '=== ' ' ===' '  ==' '   =' )

BLA::play_loading_animation_loop() {
  while true ; do
    for frame in "${BLA_active_loading_animation[@]}" ; do
      printf "\r%s" "${frame}"
      sleep "${BLA_loading_animation_frame_interval}"
    done
  done
}

BLA::start_loading_animation() {
  BLA_active_loading_animation=( "${@}" )
  BLA_loading_animation_frame_interval="${BLA_active_loading_animation[0]}"
  unset "BLA_active_loading_animation[0]"
  tput civis # Hide the terminal cursor
  BLA::play_loading_animation_loop &
  BLA_loading_animation_pid="${!}"
}

BLA::stop_loading_animation() {
  kill "${BLA_loading_animation_pid}" &> /dev/null
  printf "\n"
  tput cnorm # Restore the terminal cursor
}

#######################################################################################

# Path-Settings
installPth="/opt/piler-docker"
configPth="/opt/piler-docker/config"
etcPth="/var/lib/docker/volumes/piler-docker_piler_etc/_data"

# Load config
. ./piler.conf

############################## Installer Settings #######################################

# Piler-Domain
read -ep "Please set your Piler-Domain (Enter for default: piler.example.com): " pilerDomain
pilerDomain=${pilerDomain:=piler.example.com}
sed -i 's/PILER_DOMAIN=.*/PILER_DOMAIN="'$pilerDomain'"/g' ./piler.conf

# Piler-Admin-Mail
read -ep "Please set your Mailserver Admin Mail (Enter for default: admin@example.com): " pilerAdminMail
pilerAdminMail=${pilerAdminMail:=admin@example.com}
sed -i 's/SUPPORT_MAIL=.*/SUPPORT_MAIL="'$pilerAdminMail'"/g' ./piler.conf

# retention Days
read -ep "Please set retention days (Enter for default: 2555 Days ~ 7 Years): " retentionDays
retentionDays=${retentionDays:=2555}
sed -i 's/DEFAULT_RETENTION_DAYS=.*/DEFAULT_RETENTION_DAYS="'$retentionDays'"/g' ./piler.conf

# Smarthost
read -ep "Please set your Smarthost (Enter for default: 127.0.0.1). Default settings can be used here!!: " pilerSmartHost
pilerSmartHost=${pilerSmartHost:=127.0.0.1}
sed -i 's/SMARTHOST=.*/SMARTHOST="'$pilerSmartHost'"/g' ./piler.conf

# IMAP Server
read -ep "Please set your IMAP Server (Enter for default: imap.example.com): " imapServer
imapServer=${imapServer:=imap.example.com}
sed -i 's/IMAP_SERVER=.*/IMAP_SERVER="'$imapServer'"/g' ./piler.conf

# Timezone
read -ep "Please set your Timezone (Enter for default: Europe/Berlin): " timeZone
timeZone=${timeZone:=Europe/Berlin}
timeZone="${timeZone////\\/}"
sed -i 's/TIME_ZONE=.*/TIME_ZONE="'$timeZone'"/g' ./piler.conf

# MySql Database
read -ep "Please set your MySql Database (Enter for default: piler): " pilerDataBase
pilerDataBase=${pilerDataBase:=piler}
sed -i 's/MYSQL_DATABASE=.*/MYSQL_DATABASE="'$pilerDataBase'"/g' ./piler.conf

# MySql User
read -ep "Please set your MySql User (Enter for default: piler): " pilerUser
pilerUser=${pilerUser:=piler}
sed -i 's/MYSQL_USER=.*/MYSQL_USER="'$pilerUser'"/g' ./piler.conf

# MySql Password
read -sp "Please set your MySql Password: " pilerPassword
pilerPassword=$pilerPassword
sed -i 's/MYSQL_PASSWORD=.*/MYSQL_PASSWORD="'$pilerPassword'"/g' ./piler.conf
echo

# use Let's Encrypt
while true; do
    read -ep "Enabled / Disabled (yes/no) Let's Encrypt? For local Run disabled / Y|N: " jn
    case $jn in
        [Yy]* ) sed -i 's/USE_LETSENCRYPT=.*/USE_LETSENCRYPT="yes"/g' ./piler.conf; break;;
        [Nn]* ) sed -i 's/USE_LETSENCRYPT=.*/USE_LETSENCRYPT="no"/g' ./piler.conf; break;;
        * ) echo -e "${red} Please confirm with Y or N.";;
    esac
done

# reload config
. ./piler.conf

# Let's Encrypt registration contact information
if [ "$USE_LETSENCRYPT" = "yes" ]; then
    read -ep "Please set Let's Encrypt registration contact information (Enter for default: admin@example.com): " acmeContact
    acmeContact=${acmeContact:=admin@example.com}
    sed -i 's/LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL="'$acmeContact'"/g' ./piler.conf
fi

# use Mailcow
while true; do
    read -ep "If Use Mailcow API Options (yes/no)? / Y|N: " jn
    case $jn in
        [Yy]* ) sed -i 's/USE_MAILCOW=.*/USE_MAILCOW=true/g' ./piler.conf; break;;
        [Nn]* ) sed -i 's/USE_MAILCOW=.*/USE_MAILCOW=false/g' ./piler.conf; break;;
        * ) echo -e "${red} Please confirm with Y or N.";;
    esac
done

# reload config
. ./piler.conf

if [ "$USE_MAILCOW" = true ]; then
    # Mailcow API-Key
    read -ep "Please set your Mailcow API-Key: " apiKey
    apiKey=$apiKey
    sed -i 's/MAILCOW_APIKEY=.*/MAILCOW_APIKEY="'$apiKey'"/g' ./piler.conf

    # Mailcow Host Domain
    read -ep "Please set your Mailcow Host Domain (Enter for default: $imapServer): " mailcowHost
    mailcowHost=${mailcowHost:=$imapServer}
    sed -i 's/MAILCOW_HOST=.*/MAILCOW_HOST="'$mailcowHost'"/g' ./piler.conf
fi

echo
echo "${blue}${HLINE}"
echo "All settings were saved in the piler.conf file"
echo "and can be adjusted there at any time."
echo "${blue}${HLINE}${normal}"
echo

# uninstall Postfix
while true; do
    read -ep "Postfix must be uninstalled prior to installation. Do you want to uninstall Postfix now? (y/n): " yn
    case $yn in
        [Yy]* ) apt purge postfix -y; break;;
        [Nn]* ) echo -e "${redBold}    The installation process is aborted because Postfix has not been uninstalled.!! ${normal}"; exit;;
        * ) echo -e "${red} Please confirm with y or n.";;
    esac
done

# start piler install
while true; do
    read -ep "Do you want to start the Piler installation now? / Y|N: " yn
    case $yn in
        [Yy]* ) echo -e "${greenBold}Piler install started!! ${normal}"; break;;
        [Nn]* ) echo -e "${redBold}Aborting the Piler installation!! ${normal}"; exit;;
        * ) echo -e "${red} Please confirm with Y or N.";;
    esac
done

#########################################################################################

# reload config
. ./piler.conf

if [ ! -f $installPth/.env ]; then
    ln -s ./piler.conf .env
fi

if [ -f $installPth/docker-compose.yml ]; then
    rm $installPth/docker-compose.yml
fi

if [ "$USE_LETSENCRYPT" = "yes" ]; then
    cp $configPth/piler-ssl.yml $installPth/docker-compose.yml
else
    cp $configPth/piler-default.yml $installPth/docker-compose.yml
fi

# old docker stop
cd $installPth
docker-compose down

# docker start
echo
echo "${greenBold}${HLINE}"
echo "${greenBold}                 start docker-compose for Piler"
echo "${greenBold}${HLINE}${normal}"
echo

cd $installPth

if [ "$USE_LETSENCRYPT" = "yes" ]; then
    if ! docker network ls | grep -o "nginx-proxy"; then
        docker network create nginx-proxy

        echo
        echo "${blue}${HLINE}"
        echo "${blue}                       docker network created"
        echo "${blue}${HLINE}${normal}"
        echo
    fi
fi

docker-compose up -d

echo "${blue}********* Piler started... Please wait... *********"

BLA::start_loading_animation "${BLA_metro[@]}"
sleep 20
BLA::stop_loading_animation

echo
echo "${blue}${HLINE}"
echo "${blue}             backup the File config-site.php"
echo "${blue}${HLINE}${normal}"
echo

if [ ! -f $etcPth/config-site.php.bak ]; then
    cp $etcPth/config-site.php $etcPth/config-site.php.bak
else
    rm $etcPth/config-site.php
    cp $etcPth/config-site.php.bak $etcPth/config-site.php
fi

echo
echo "${blue}${HLINE}"
echo "${blue}                       set User settings ..."
echo "${blue}${HLINE}${normal}"
echo

cat >> $etcPth/config-site.php <<EOF

// Smarthost
\$config['SMARTHOST'] = '$SMARTHOST';
\$config['SMARTHOST_PORT'] = '25';

// CUSTOM
\$config['PROVIDED_BY'] = '$PILER_DOMAIN';
\$config['SUPPORT_LINK'] = 'mailto:$SUPPORT_MAIL';
\$config['COMPATIBILITY'] = '';

// fancy features.
\$config['ENABLE_INSTANT_SEARCH'] = 1;
\$config['ENABLE_TABLE_RESIZE'] = 1;

\$config['ENABLE_DELETE'] = 1;
\$config['ENABLE_ON_THE_FLY_VERIFICATION'] = 1;

// general settings.
\$config['TIMEZONE'] = '$TIME_ZONE';

// authentication
// Enable authentication against an imap server
\$config['ENABLE_IMAP_AUTH'] = 1;
\$config['RESTORE_OVER_IMAP'] = 1;
\$config['IMAP_RESTORE_FOLDER_INBOX'] = 'INBOX';
\$config['IMAP_RESTORE_FOLDER_SENT'] = 'Sent';
\$config['IMAP_HOST'] = '$IMAP_SERVER';
\$config['IMAP_PORT'] =  993;
\$config['IMAP_SSL'] = true;

// authentication against an ldap directory (disabled by default)
//\$config['ENABLE_LDAP_AUTH'] = 1;
//\$config['LDAP_HOST'] = '$SMARTHOST';
//\$config['LDAP_PORT'] = 389;
//\$config['LDAP_HELPER_DN'] = 'cn=administrator,cn=users,dc=mydomain,dc=local';
//\$config['LDAP_HELPER_PASSWORD'] = 'myxxxxpasswd';
//\$config['LDAP_MAIL_ATTR'] = 'mail';
//\$config['LDAP_AUDITOR_MEMBER_DN'] = '';
//\$config['LDAP_ADMIN_MEMBER_DN'] = '';
//\$config['LDAP_BASE_DN'] = 'ou=Benutzer,dc=krs,dc=local';

// authentication against an Uninvention based ldap directory 
//\$config['ENABLE_LDAP_AUTH'] = 1;
//\$config['LDAP_HOST'] = '$SMARTHOST';
//\$config['LDAP_PORT'] = 7389;
//\$config['LDAP_HELPER_DN'] = 'uid=ldap-search-user,cn=users,dc=mydomain,dc=local';
//\$config['LDAP_HELPER_PASSWORD'] = 'myxxxxpasswd';
//\$config['LDAP_AUDITOR_MEMBER_DN'] = '';
//\$config['LDAP_ADMIN_MEMBER_DN'] = '';
//\$config['LDAP_BASE_DN'] = 'cn=users,dc=mydomain,dc=local';
//\$config['LDAP_MAIL_ATTR'] = 'mailPrimaryAddress';
//\$config['LDAP_ACCOUNT_OBJECTCLASS'] = 'person';
//\$config['LDAP_DISTRIBUTIONLIST_OBJECTCLASS'] = 'person';
//\$config['LDAP_DISTRIBUTIONLIST_ATTR'] = 'mailAlternativeAddress';

// special settings.
//\$config['MEMCACHED_ENABLED'] = 1;
\$config['SPHINX_STRICT_SCHEMA'] = 1; // required for Sphinx see https://bitbucket.org/jsuto/piler/issues/1085/sphinx-331.
EOF

if [ "$USE_MAILCOW" = true ]; then

echo
echo "${blue}${HLINE}"
echo "set Mailcow Api-Key config"
echo "${blue}${HLINE}${normal}"
echo

cat >> $etcPth/config-site.php <<EOF

// Mailcow API
\$config['MAILCOW_API_KEY'] = '$MAILCOW_APIKEY';
\$config['MAILCOW_SET_REALNAME'] = true;
\$config['CUSTOM_EMAIL_QUERY_FUNCTION'] = 'query_mailcow_for_email_access';
\$config['MAILCOW_HOST'] = '$MAILCOW_HOST'; // default $config['IMAP_HOST']
include('auth-mailcow.php');
EOF

curl -o $etcPth/auth-mailcow.php https://raw.githubusercontent.com/patschi/mailpiler-mailcow-integration/master/auth-mailcow.php
fi

# add config settings

if [ ! -f $etcPth/piler.conf.bak ]; then
    cp $etcPth/piler.conf $etcPth/piler.conf.bak
else
    rm $etcPth/piler.conf
    cp $etcPth/piler.conf.bak $etcPth/piler.conf
fi

sed -i "s/default_retention_days=.*/default_retention_days=$DEFAULT_RETENTION_DAYS/" $etcPth/piler.conf
sed -i "s/update_counters_to_memcached=.*/update_counters_to_memcached=1/" $etcPth/piler.conf

cat >> $etcPth/piler.conf <<EOF
queuedir=/var/piler/store
EOF

# piler restart
echo
echo "${blue}${HLINE}"
echo "${blue}                  restart piler ..."
echo "${blue}${HLINE}${normal}"
echo

cd $installPth
docker-compose restart piler

echo
echo "${greenBold}${HLINE}"
echo "${greenBold}             Piler install completed successfully"
echo "${greenBold}${HLINE}${normal}"
echo
echo
echo "${greenBold}${HLINE}"
if [ "$USE_LETSENCRYPT" = "yes" ]; then
    echo "${greenBold}you can start in your Browser with https://${PILER_DOMAIN}!"
else
    echo "${greenBold}you can start in your Browser with:"
    echo "${greenBold}http://${PILER_DOMAIN} or http://local-ip"
fi
echo "${greenBold}${HLINE}${normal}"
echo
