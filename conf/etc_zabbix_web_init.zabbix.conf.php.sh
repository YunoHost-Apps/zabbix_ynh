#!/bin/bash

app="zabbix"

if [ ! -L "/usr/share/zabbix/conf/zabbix.conf.php" ]
then
	ln -s /etc/zabbix/web/zabbix.conf.php /usr/share/zabbix/conf/zabbix.conf.php
fi

if [ ! -f /etc/zabbix/web/zabbix.conf.php ]
then
	echo "<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = '"$(yunohost app setting zabbix db_name)"';
\$DB['USER']     = '"$(yunohost app setting zabbix db_user)"';
\$DB['PASSWORD'] = '"$(yunohost app setting zabbix mysqlpwd)"';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;">/etc/zabbix/web/zabbix.conf.php

	chown $app:www-data "/etc/zabbix/web/zabbix.conf.php"
fi
