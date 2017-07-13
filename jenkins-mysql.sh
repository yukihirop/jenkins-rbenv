#! /bin/bash

echo "Starting Jenkins"
/usr/local/bin/jenkins.sh &

# 172.17.0.82など
DB_HOSTNAME=$MYSQL_PORT_3306_TCP_ADDR
# port番号
DB_PORT=$MYSQL_PORT_3306_TCP_PORT
DB_DATABASE=jenkins
DB_USER=jenkins
DB_PASSWORD=$JENKINS_DB_PASSWORD

echo "Creating MySQL database"

MYSQL_CONFIG=/var/jenkins_home/.mysql

cat << EOF > $MYSQL_CONFIG
[client]
host=$DB_HOSTNAME
port=$DB_PORT
user=root
password=$MYSQL_ENV_MYSQL_ROOT_PASSWORD
EOF

# 設定を読み込むさき defaults-extra-file
cat << EOF | mysql --defaults-extra-file=$MYSQL_CONFIG

CREATE DATABASE IF NOT EXISTS $DB_DATABASE;
GRANT ALL ON *.* TO $DB_USER@'%' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION;
FLUSH PRIVILEGES;

EOF

rm -f $MYSQL_CONFIG



echo "Configuring Jenkins for MySQL"

cat << EOF | java -jar /var/jenkins_home/jenkins-cli.jar -s http://localhost:8080/ groovy =

import hudson.model.*;
import hudson.util.*;
import jenkins.model.*;
import org.jenkinsci.plugins.database.*;
import org.jenkinsci.plugins.database.mysql.*;

//db = hudson.model.Hudson.instance.pluginManager.getPlugin("database")

config = Jenkins.getInstance().getDescriptor( GlobalDatabaseConfiguration.class )
db = new MySQLDatabase("$DB_HOSTNAME:$DB_PORT", "$DB_DATABASE", "$DB_USER", Secret.fromString("$DB_PASSWORD"), "")
config.setDatabase(db)

println "Jenkins configured to use MySQL at $DB_USER@$DB_HOSTNAME:$DB_PORT/$DB_DATABASE"

EOF

wait
