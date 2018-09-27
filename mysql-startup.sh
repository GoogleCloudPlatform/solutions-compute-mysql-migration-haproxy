#!/usr/bin/env bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
apt-get update
# Vars to be used later
PASS="solution-admin"
LOCAL_IP=`curl  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H "Metadata-Flavor: Google"`
MYSQL_ROLE=`curl -sS "http://metadata.google.internal/computeMetadata/v1/instance/attributes/mysql-role" -H "Metadata-Flavor: Google"`
# Important for configuring the server id in MySQL config
[[ ${MYSQL_ROLE} == "primary" ]] && SERVER_ID="1" || SERVER_ID="2"

# This allows us to set the root password for the MySQL server
echo "mysql-server-5.7 mysql-server/root_password password ${PASS}" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password ${PASS}" | sudo debconf-set-selections

apt-get install -y mysql-server-5.7

# Setting values in MySQL configuration
sed -i "s|#server-id.*|server-id = ${SERVER_ID}|" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s|#log_bin.*|log_bin = /var/log/mysql/mysql-bin.log|" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s|expire_logs_days.*|expire_logs_days = 10|" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s|max_binlog_size.*|max_binlog_size = 100M|" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s|#binlog_do_db.*|binlog_do_db = source_db|" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s|bind-address.*|bind-address = ${LOCAL_IP}|" /etc/mysql/mysql.conf.d/mysqld.cnf
if [[ ${MYSQL_ROLE} == "primary" ]] ; then
    echo "log_slave_updates = 1" >> /etc/mysql/mysql.conf.d/mysqld.cnf
fi

service mysql restart

if [[ ${MYSQL_ROLE} == "primary" ]] ; then
    mysql -u root -p${PASS} -e "GRANT REPLICATION SLAVE ON *.* TO 'sourcereplicator'@'%' IDENTIFIED BY '"${PASS}"'";

# This creates SQL script that populates a sample database with random data
# Database name : source_db
# Table name : source_table
cat <<EOF > db_creation.sql
CREATE DATABASE source_db;
use source_db;
CREATE TABLE source_table
(
	id BIGINT NOT NULL AUTO_INCREMENT,
	timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	event_data float DEFAULT NULL,
	PRIMARY KEY (id)
	
);
DELIMITER $$
CREATE PROCEDURE simulate_data()
BEGIN
	DECLARE i INT DEFAULT 0;
	WHILE i < 5000 DO
		INSERT INTO source_table (event_data) VALUES (ROUND(RAND()*15000,2));
		SET i = i + 1;
	END WHILE;
	

END$$
DELIMITER ;
CALL simulate_data()

EOF

mysql -u root -p${PASS} < db_creation.sql
fi

if [[ ${MYSQL_ROLE} == "replica" ]]; then
    #Setting up the replication
    mysql -u root -p$PASS -e "change master to master_host='source-mysql-primary', master_user='sourcereplicator',master_password='"${PASS}"'";
    mysql -u root -p$PASS -e "reset slave; start slave;"
fi
