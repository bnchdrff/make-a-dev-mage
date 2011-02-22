#!/bin/bash
# commit any changes before doing this, for ease of use

PREFIX="mage_"

SRC_DBFILE="/path/to/dbdump.sql"
SRC_DBUSER="livedbuser"
SRC_DBPASS="livedbpass"
SRC_DBNAME="livedbuser_dbname"

DST_URL="http://dev.site.name/"
DST_DBUSER="devuser"
DST_DBPASS="devpass"
DST_DBNAME="devuser_dbname"
SRC_DIR="/path/to/livemage"
DST_DIR="/path/to/devmage"

TESTING_AUTHNET_LOGIN=""
TESTING_AUTHNET_TRANSKEY=""

TESTING_MAIL="user@example.com"

SEED=$(dd if=/dev/urandom  bs=1 count=11 status=noxfer 2>/dev/null|md5sum)
RAND=${SEED:0:8}

rm -rf $DST_DIR
rsync -a $SRC_DIR/ $DST_DIR/
echo "drop database $DST_DBNAME" | mysql -u $DST_DBUSER -p$DST_DBPASS
echo "create database $DST_DBNAME" | mysql -u $DST_DBUSER -p$DST_DBPASS
mysql  -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME < $SRC_DBFILE
rm -rf $DST_DIR/var/cache/*
rm -rf $DST_DIR/var/session/*
echo "update ${PREFIX}core_config_data set value='$DST_URL' where path like 'web/%/base_url';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "update ${PREFIX}core_config_data set value='$TESTING_MAIL' where value like '%@%.com';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "update ${PREFIX}core_config_data set value='$TESTING_MAIL' where value like '%@%.org';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "update ${PREFIX}core_config_data set value='$TESTING_MAIL' where value like '%@%.net';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME

echo "update ${PREFIX}core_config_data set value='1' where path like 'payment/authorizenet/debug';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "update ${PREFIX}core_config_data set value='1' where value like 'payment/authorizenet/test';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "update ${PREFIX}core_config_data set value='$TESTING_AUTHNET_LOGIN' where value like 'payment/authorizenet/login';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "update ${PREFIX}core_config_data set value='$TESTING_AUTHNET_TRANSKEY' where value like 'payment/authorizenet/transkey';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME

sed -i "s/<prefix>[a-zA-Z]*<\/prefix>/<prefix>$DST_DBNAME<\/prefix>/" $DST_DIR/app/etc/local.xml
sed -i "s/<username><\!\[CDATA\[$SRC_DBUSER\]\]><\/username>/<username><![CDATA[$DST_DBUSER]]><\/username>/" $DST_DIR/app/etc/local.xml
sed -i "s/<password><\!\[CDATA\[$SRC_DBPASS\]\]><\/password>/<password><![CDATA[$DST_DBPASS]]><\/password>/" $DST_DIR/app/etc/local.xml
sed -i "s/<dbname><\!\[CDATA\[$SRC_DBNAME\]\]><\/dbname>/<dbname><![CDATA[$DST_DBNAME]]><\/dbname>/" $DST_DIR/app/etc/local.xml

