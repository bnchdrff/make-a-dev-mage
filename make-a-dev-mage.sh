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
mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME < $SRC_DBFILE

# induce amnesia
rm -rf $DST_DIR/var/cache/*
rm -rf $DST_DIR/var/session/*

# send me mixed messages
echo "UPDATE \`${PREFIX}core_config_data\` SET value='$DST_URL' WHERE path LIKE 'web/%/base_url';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "UPDATE \`${PREFIX}core_config_data\` SET value='$TESTING_MAIL' WHERE value LIKE '%@%.com';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "UPDATE \`${PREFIX}core_config_data\` SET value='$TESTING_MAIL' WHERE value LIKE '%@%.org';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "UPDATE \`${PREFIX}core_config_data\` SET value='$TESTING_MAIL' WHERE value LIKE '%@%.net';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME

# everything is debug
echo "UPDATE \`${PREFIX}core_config_data\` SET value='1' WHERE path LIKE 'payment/authorizenet/debug';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "UPDATE \`${PREFIX}core_config_data\` SET value='1' WHERE value LIKE 'payment/authorizenet/test';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "UPDATE \`${PREFIX}core_config_data\` SET value='$TESTING_AUTHNET_LOGIN' WHERE value LIKE 'payment/authorizenet/login';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME
echo "UPDATE \`${PREFIX}core_config_data\` SET value='$TESTING_AUTHNET_TRANSKEY' WHERE value LIKE 'payment/authorizenet/transkey';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME

# everything is free
echo "INSERT INTO \`${PREFIX}catalogrule\` VALUES(2,'dev','','2011-02-23','2022-04-23','0,1,2,3',1,'a:6:{s:4:\"type\";s:34:\"catalogrule/rule_condition_combine\";s:9:\"attribute\";N;s:8:\"operator\";N;s:5:\"value\";s:1:\"1\";s:18:\"is_value_processed\";N;s:10:\"aggregator\";s:3:\"all\";}','a:4:{s:4:\"type\";s:34:\"catalogrule/rule_action_collection\";s:9:\"attribute\";N;s:8:\"operator\";s:1:\"=\";s:5:\"value\";N;}',0,0,'by_percent','100.0000','1');" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME

echo "UPDATE \`${PREFIX}core_config_data\` SET value=1 WHERE path='carriers/freeshipping/active';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME

echo "UPDATE \`${PREFIX}core_config_data\` SET value=1 WHERE path='payment/free/active';" | mysql -u $DST_DBUSER -p$DST_DBPASS $DST_DBNAME

sed -i "s/<prefix>[a-zA-Z]*<\/prefix>/<prefix>$DST_DBNAME<\/prefix>/" $DST_DIR/app/etc/local.xml
sed -i "s/<username><\!\[CDATA\[$SRC_DBUSER\]\]><\/username>/<username><![CDATA[$DST_DBUSER]]><\/username>/" $DST_DIR/app/etc/local.xml
sed -i "s/<password><\!\[CDATA\[$SRC_DBPASS\]\]><\/password>/<password><![CDATA[$DST_DBPASS]]><\/password>/" $DST_DIR/app/etc/local.xml
sed -i "s/<dbname><\!\[CDATA\[$SRC_DBNAME\]\]><\/dbname>/<dbname><![CDATA[$DST_DBNAME]]><\/dbname>/" $DST_DIR/app/etc/local.xml

