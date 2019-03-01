#!/bin/bash

# ============= FUTURE YUNOHOST HELPER =============
# Delete a file checksum from the app settings
#
# $app should be defined when calling this helper
#
# usage: ynh_remove_file_checksum file
# | arg: file - The file for which the checksum will be deleted
ynh_delete_file_checksum () {
	local checksum_setting_name=checksum_${1//[\/ ]/_}	# Replace all '/' and ' ' by '_'
	ynh_app_setting_delete $app $checksum_setting_name
}

#Zabbix part
#===================GET GUEST DEFAULT USER STATE==============
#return 0 if enable, else 1
get_state_guest_user(){
    return $($mysqlconn -BN -e "SELECT count(id) from \`users_groups\` where userid=2 and usrgrpid=9")
}

#================ DISABLE DEFAULT ZABBIX USER GUEST ===================

disable_guest_user(){
    if [ get_state_guest_user -eq 0 ];then
        lastid=$($mysqlconn -BN -e "SELECT max(id) from \`users_groups\`")
        lastid=$(("$lastid" + 1 ))
        $mysqlconn -e "INSERT INTO \`users_groups\` (\`id\` , \`usrgrpid\`, \`userid\`) VALUES ($lastid ,9, 2);"
    fi
}

#===================GET ADMIN DEFAULT USER STATE==============
#return 0 if enable, else 1
get_state_admin_user(){
    return $($mysqlconn -BN -e "SELECT count(id) from \`users_groups\` where userid=1 and usrgrpid=9")
}

#================ DISABLE DEFAULT ADMIN USER ===================
disable_admin_user(){
    if [ get_state_admin_user -eq 0 ] ;then
        lastid=$($mysqlconn -BN -e "SELECT max(id) from \`users_groups\`")
        lastid=$((lastid + 1 ))
        $mysqlconn -e "INSERT INTO \`users_groups\` (\`id\` , \`usrgrpid\`, \`userid\`) VALUES ($lastid ,9, 1);"
    fi
}

enable_admin_user(){
    if [ get_state_admin_user -eq 1 ] ;then
        ynh_print_info "Enable default admin"
        #enable default admin temporaly
        mysql -u"$db_user" -p"$db_pwd" "$db_name" -e "DELETE FROM users_groups where usrgrpid=9 and userid=1;"
    fi
}