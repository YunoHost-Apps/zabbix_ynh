#!/bin/bash

# Get guest user state
#
# return 0 if enable, else 1
#
get_state_guest_user () {
	$mysqlconn -BN -e "SELECT count(id) from \`users_groups\` where userid=2 and usrgrpid=9"
}

# Disable guest user
#
disable_guest_user () {
	if [ $(get_state_guest_user) = "0" ]
	then
		ynh_print_info --message="Disable guest user"
		lastid=$($mysqlconn -BN -e "SELECT max(id) from \`users_groups\`")
		lastid=$(("$lastid" + 1 ))
		$mysqlconn -e "INSERT INTO \`users_groups\` (\`id\` , \`usrgrpid\`, \`userid\`) VALUES ($lastid ,9, 2);"
		ynh_print_info --message="Guest user disabled"
	else
		ynh_print_info --message="Guest user already disabled"
	fi
}

# Get admin user state
#
# return 0 if enable, else 1
#
get_state_admin_user () {
	$mysqlconn -BN -e "SELECT count(id) from \`users_groups\` where userid=1 and usrgrpid=9"
}

# Disable admin user
#
disable_admin_user () {
	if [ $(get_state_admin_user) = "0" ]
	then
		ynh_print_info --message="Disable admin user"
		lastid=$($mysqlconn -BN -e "SELECT max(id) from \`users_groups\`")
		lastid=$((lastid + 1 ))
		$mysqlconn -e "INSERT INTO \`users_groups\` (\`id\` , \`usrgrpid\`, \`userid\`) VALUES ($lastid ,9, 1);"
		ynh_print_info --message="Admin user disabled"
	else
		ynh_print_info --message="Admin user already disabled"
	fi
}

# Enable admin user
#
enable_admin_user () {
	if [ $(get_state_admin_user) = "1" ]
	then
		ynh_print_info --message="Enable admin user"
		#enable default admin temporaly
		$mysqlconn -e "DELETE FROM users_groups where usrgrpid=9 and userid=1;"
		ynh_print_info --message="Admin user enabled"
	else
		ynh_print_info --message="Admin user already enable"
	fi
}

# Import YunoHost template in the agent
#
import_template () {
	ynh_print_info --message="Import YunoHost template in the agent"
	zabbixFullpath=https://$domain$path
	localpath="../conf/Template_Yunohost.xml"
	sudoUserPpath="../conf/etc_sudoers.d_zabbix"
	confUserPpath="../conf/etc_zabbix_zabbix_agentd.d_userP_yunohost.conf"
	bashUserPpath="../conf/etc_zabbix_zabbix_agentd.d_yunohost.sh"

	cp "$sudoUserPpath" /etc/sudoers.d/zabbix
	chmod 400 /etc/sudoers.d/zabbix

	if [ -d /etc/zabbix/zabbix_agentd.d ]
	then
		mv /etc/zabbix/zabbix_agentd.d /etc/zabbix/zabbix_agentd.conf.d
	fi
	if [ ! -L /etc/zabbix/zabbix_agentd.d ]
	then
		ln -s /etc/zabbix/zabbix_agentd.conf.d /etc/zabbix/zabbix_agentd.d
	fi

	cp "$confUserPpath" /etc/zabbix/zabbix_agentd.d/userP_yunohost.conf
	cp "$bashUserPpath" /etc/zabbix/zabbix_agentd.d/yunohost.sh
	chown -R $app:$app "/etc/zabbix/zabbix_agentd.d/"
	chmod a+x /etc/zabbix/zabbix_agentd.d/yunohost.sh

	systemctl restart zabbix-agent

	/usr/share/zabbix-cli/bin/zabbix-cli --config /usr/share/zabbix-cli/zabbix-cli.toml import_configuration $localpath
}

# Link YunoHost template to Zabbix server
#
link_template () {
	ynh_print_info --message="Link YunoHost template to Zabbix server"

	/usr/share/zabbix-cli/bin/zabbix-cli --config /usr/share/zabbix-cli/zabbix-cli.toml link_template_to_host "Template Yunohost" "Zabbix server"
}

# Check if Zabbix server is started
#
check_proc_zabbixserver () {
	pgrep zabbix_server >/dev/null
	if [ $? -eq 0 ]
	then
		ynh_print_info --message="Zabbix server is started !"
	else
		ynh_print_err --message="Zabbix server not started, try to start it with the YunoHost interface."
		ynh_print_err --message="If Zabbix server can't start, please open a issue on https://github.com/YunoHost-Apps/zabbix_ynh/issues"
	fi
}

# Check if Zabbix agent is started
#
check_proc_zabbixagent () {
	pgrep zabbix_agentd >/dev/null
	if [ $? -eq 0 ]
	then
		ynh_print_info --message="Zabbix agent is started"
	else
		ynh_print_err --message="Zabbix agent not started, try to start it with the YunoHost interface."
		ynh_print_err --message="If Zabbix agent can't start, please open a issue on https://github.com/YunoHost-Apps/zabbix_ynh/issues"
	fi
}


# Update Zabbix configuration initialisation
#
update_initZabbixConf () {
	ynh_print_info --message="Update Zabbix configuration initialisation !"
	if [ ! -d /etc/zabbix/web ]
	then
		mkdir -p /etc/zabbix/web
	fi
	cp "../conf/etc_zabbix_web_init.zabbix.conf.php.sh" /etc/zabbix/web/init.zabbix.conf.php.sh
	chmod 700 /etc/zabbix/web/init.zabbix.conf.php.sh
	cp "../conf/etc_apt_apt.conf.d_100update_force_init_zabbix_frontend_config" /etc/apt/apt.conf.d/100update_force_init_zabbix_frontend_config
	ynh_print_info --message="Zabbix configuration initialisation updated !"
}

# Delete Zabbix configuration initialisation
#
delete_initZabbixConf () {
	ynh_print_info --message="Delete Zabbix configuration initialisation !"
	if [ -f /etc/zabbix/web/init.zabbix.conf.php.sh ]
	then
		ynh_secure_remove --file="/etc/zabbix/web/init.zabbix.conf.php.sh"
	fi
	if [ -f /etc/apt/apt.conf.d/100update_force_init_zabbix_frontend_config ]
	then
		ynh_secure_remove --file="/etc/apt/apt.conf.d/100update_force_init_zabbix_frontend_config"
	fi
	ynh_print_info --message="Zabbix configuration initialisation deleted !"
}

# Patch timeout too short for Zabbix agent if needed
#
change_timeoutAgent () {
	timeout_ok=$(grep "^Timeout" /etc/zabbix/zabbix_agentd.conf 2>/dev/null || true;)
	if [ -z "$timeout_ok" ]
	then
		ynh_replace_string --match_string="# Timeout=3" --replace_string="Timeout=10" --target_file=/etc/zabbix/zabbix_agentd.conf
		grep -C 2 "Timeout" /etc/zabbix/zabbix_agentd.conf
		systemctl restart zabbix-agent
		ynh_print_info --message="Zabbix agent timeout updated !"
	fi
}

# Update Zabbix database character set
#
convert_ZabbixDB () {
	ynh_print_info --message="Zabbix database character set will be updated !"
	$mysqlconn -e "ALTER DATABASE $db_name CHARACTER SET utf8 COLLATE utf8_general_ci;"
	for t in $($mysqlconn -BN -e "show tables";)
	do
		$mysqlconn -e "ALTER TABLE $t CONVERT TO character set utf8 collate utf8_bin;"
	done
	ynh_print_info --message="Zabbix database character set has been updated !"
}

# Add email media type with the YunoHost server mail.
#
set_mediatype_default_yunohost () {
	set -x
	if [ $($mysqlconn -BN -e "SELECT count(*) FROM media_type WHERE smtp_server LIKE 'mail.example.com' AND status=1;") -eq 1 ]
	then
		$mysqlconn -BN -e "UPDATE media_type SET smtp_server = 'localhost', smtp_helo = '"$domain"', smtp_email = 'zabbix@"$domain"', smtp_port = '587', status=0 , smtp_security=1 WHERE smtp_server LIKE 'mail.example.com' AND status=1;"
		ynh_print_info --message="Default Media type added !"
	fi
	set +x
}
