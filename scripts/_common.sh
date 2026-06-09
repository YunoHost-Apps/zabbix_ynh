#!/bin/bash

readonly zabbix_username='cli-ynh-superadmin'
readonly timezone=$(cat /etc/timezone)
readonly zabbixFullpath="https://$domain$path"
readonly zabbix_tools="$install_dir/zabbix_api/bin/python3 zabbix_tools.py"

# Import YunoHost template in the agent
#
import_template () {
	ynh_print_info "Import YunoHost template in the agent"

	ynh_config_add --template='etc_zabbix_zabbix_agentd.d_userP_yunohost.conf' --destination='/etc/zabbix/zabbix_agentd.d/userP_yunohost.conf'

	systemctl restart zabbix-agent

	$zabbix_tools import_template
}

# Check if Zabbix server is started
#
check_proc_zabbixserver () {
	pgrep zabbix_server >/dev/null
	if [ $? -eq 0 ]
	then
		ynh_print_info "Zabbix server is started !"
	else
		ynh_print_warn "Zabbix server not started, try to start it with the YunoHost interface."
		ynh_print_warn "If Zabbix server can't start, please open a issue on https://github.com/YunoHost-Apps/zabbix_ynh/issues"
	fi
}

# Check if Zabbix agent is started
#
check_proc_zabbixagent () {
	pgrep zabbix_agentd >/dev/null
	if [ $? -eq 0 ]
	then
		ynh_print_info "Zabbix agent is started"
	else
		ynh_print_warn "Zabbix agent not started, try to start it with the YunoHost interface."
		ynh_print_warn "If Zabbix agent can't start, please open a issue on https://github.com/YunoHost-Apps/zabbix_ynh/issues"
	fi
}


# Update Zabbix configuration initialisation
#
update_initZabbixConf () {
	ynh_print_info "Update Zabbix configuration initialisation !"

	ynh_config_add --template="etc_apt_apt.conf.d_100update_force_init_zabbix_frontend_config" --destination=/etc/apt/apt.conf.d/100update_force_init_zabbix_frontend_config
}

# Delete Zabbix configuration initialisation
#
delete_initZabbixConf () {
	ynh_print_info "Delete Zabbix configuration initialisation !"
	if [ -f /etc/zabbix/web/init.zabbix.conf.php.sh ]
	then
		ynh_safe_rm "/etc/zabbix/web/init.zabbix.conf.php.sh"
	fi
	if [ -f /etc/apt/apt.conf.d/100update_force_init_zabbix_frontend_config ]
	then
		ynh_safe_rm "/etc/apt/apt.conf.d/100update_force_init_zabbix_frontend_config"
	fi
	ynh_print_info "Zabbix configuration initialisation deleted !"
}

# Patch timeout too short for Zabbix agent if needed
#
change_timeoutAgent () {
	timeout_ok=$(grep "^Timeout" /etc/zabbix/zabbix_agentd.conf 2>/dev/null || true;)
	if [ -z "$timeout_ok" ]
	then
		ynh_replace --match="# Timeout=3" --replace="Timeout=10" --file=/etc/zabbix/zabbix_agentd.conf
		grep -C 2 "Timeout" /etc/zabbix/zabbix_agentd.conf
		ynh_print_info "Zabbix agent timeout updated !"
	fi
}

# Update Zabbix database character set
#
convert_ZabbixDB () {
	ynh_print_info "Zabbix database character set will be updated !"
	$mysqlconn -e "ALTER DATABASE $db_name CHARACTER SET utf8 COLLATE utf8_general_ci;"
	for t in $($mysqlconn -BN -e "show tables";)
	do
		$mysqlconn -e "ALTER TABLE $t CONVERT TO character set utf8 collate utf8_bin;"
	done
	ynh_print_info "Zabbix database character set has been updated !"
}

set_permissions() {
	chmod -R o-rwx "/usr/share/zabbix"
	chown -R "$app:www-data" "/usr/share/zabbix"
	chmod 644 "/etc/apt/preferences.d/zabbix_repo"
	chmod 400 "/etc/zabbix/web/zabbix.conf.php"
	chown "$app:www-data" "/etc/zabbix/web/zabbix.conf.php"

	chmod u+rwX,g+rX,o-rwx -R '/etc/zabbix'
	chown "$app:$app" -R '/etc/zabbix'

	chmod 400 /etc/sudoers.d/zabbix

	chmod 750 "$install_dir/scripts/"*
	chown "$app:$app" -R "$install_dir"
}
