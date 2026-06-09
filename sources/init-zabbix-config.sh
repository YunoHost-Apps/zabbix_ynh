#!/bin/bash

set -eu

YNH_HELPERS_VERSION=2.1
app=__APP__
YNH_APP_BASEDIR=/etc/yunohost/apps/"$app"
YNH_APP_ACTION=''

source /usr/share/yunohost/helpers

db_name=$(ynh_app_setting_get --key=db_name)
db_user=$(ynh_app_setting_get --key=db_user)
db_pwd=$(ynh_app_setting_get --key=db_pwd)

ynh_config_add --template="zabbix.conf.php" --destination='/etc/zabbix/web/zabbix.conf.php'
