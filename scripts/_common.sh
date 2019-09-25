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
    $mysqlconn -BN -e "SELECT count(id) from \`users_groups\` where userid=2 and usrgrpid=9"
}

#================ DISABLE DEFAULT ZABBIX USER GUEST ===================

disable_guest_user(){
    if [ $(get_state_guest_user) = "0" ];then
        lastid=$($mysqlconn -BN -e "SELECT max(id) from \`users_groups\`")
        lastid=$(("$lastid" + 1 ))
        $mysqlconn -e "INSERT INTO \`users_groups\` (\`id\` , \`usrgrpid\`, \`userid\`) VALUES ($lastid ,9, 2);"
    fi
}

#===================GET ADMIN DEFAULT USER STATE==============
#return 0 if enable, else 1
get_state_admin_user(){
    $mysqlconn -BN -e "SELECT count(id) from \`users_groups\` where userid=1 and usrgrpid=9"
}

#================ DISABLE DEFAULT ADMIN USER ===================
disable_admin_user(){
    if [ $(get_state_admin_user) = "0" ] ;then
        lastid=$($mysqlconn -BN -e "SELECT max(id) from \`users_groups\`")
        lastid=$((lastid + 1 ))
        $mysqlconn -e "INSERT INTO \`users_groups\` (\`id\` , \`usrgrpid\`, \`userid\`) VALUES ($lastid ,9, 1);"
        ynh_print_info "Default admin disabled"

    else
        ynh_print_info "Default admin already disabled"

    fi
}

enable_admin_user(){
    if [ $(get_state_admin_user) = "1" ] ;then
        ynh_print_info "Enable default admin"
        #enable default admin temporaly
        $mysqlconn -e "DELETE FROM users_groups where usrgrpid=9 and userid=1;"
        ynh_print_info "Default admin enabled"
    else
        ynh_print_info "Default admin already enable"
    fi
}

import_template(){
    ynh_print_info "Import yunohost template"
    zabbixFullpath=https://$domain$path_url
    localpath=$(find /var/cache/yunohost/ -name "Template_Yunohost.xml")
    sudoUserPpath=$(find /var/cache/yunohost/ -name "etc_sudoers.d_zabbix")
    confUserPpath=$(find /var/cache/yunohost/ -name "etc_zabbix_zabbix_agentd.d_userP_yunohost.conf")
    bashUserPpath=$(find /var/cache/yunohost/ -name "etc_zabbix_zabbix_agentd.d_yunohost.sh")
    
    
    cp "$sudoUserPpath" /etc/sudoers.d/zabbix
    
    if [ -d /etc/zabbix/zabbix_agentd.d ];then
	    mv /etc/zabbix/zabbix_agentd.d /etc/zabbix/zabbix_agentd.conf.d
    fi
    if [ ! -L /etc/zabbix/zabbix_agentd.d ];then
    	ln -s /etc/zabbix/zabbix_agentd.conf.d /etc/zabbix/zabbix_agentd.d
    fi
    
    cp "$confUserPpath" /etc/zabbix/zabbix_agentd.d/userP_yunohost.conf
    cp "$bashUserPpath" /etc/zabbix/zabbix_agentd.d/yunohost.sh
    chmod a+x /etc/zabbix/zabbix_agentd.d/yunohost.sh
    
    systemctl restart zabbix-agent
    curlOptions="--noproxy $domain -k -s --cookie cookiejar.txt --cookie-jar cookiejar.txt --resolve $domain:443:127.0.0.1"
    
    curl -L $curlOptions \
                    --form "enter=Sign+in" \
                    --form "name=Admin" \
                    --form "password=zabbix" \
                    "$zabbixFullpath/index.php"
                    
    if [ $? -eq 0 ];then
        sid=$(curl $curlOptions \
                        "$zabbixFullpath/conf.import.php?rules_preset=template" \
                        | grep -Po 'name="sid" value="\K([a-z0-9]{16})(?=")' ) 
        
        importState=$(curl $curlOptions \
                        --form "config=1" \
                        --form "import_file=@$localpath"  \
                        --form "rules[groups][createMissing]=1" \
                        --form "rules[templates][updateExisting]=1" \
                        --form "rules[templates][createMissing]=1" \
                        --form "rules[templateScreens][updateExisting]=1" \
                        --form "rules[templateScreens][createMissing]=1" \
                        --form "rules[templateLinkage][createMissing]=1" \
                        --form "rules[applications][createMissing]=1" \
                        --form "rules[items][updateExisting]=1" \
                        --form "rules[items][createMissing]=1" \
                        --form "rules[discoveryRules][updateExisting]=1" \
                        --form "rules[discoveryRules][createMissing]=1" \
                        --form "rules[triggers][updateExisting]=1" \
                        --form "rules[triggers][createMissing]=1" \
                        --form "rules[graphs][updateExisting]=1" \
                        --form "rules[graphs][createMissing]=1" \
                        --form "rules[httptests][updateExisting]=1" \
                        --form "rules[httptests][createMissing]=1" \
                        --form "rules[valueMaps][createMissing]=1" \
                        --form "import=Import"  \
                        --form "backurl=templates.php"  \
                        --form "form_refresh=1"  \
                        --form "sid=${sid}" \  \
                        "${zabbixFullpath}/conf.import.php?rules_preset=template" \
                        | grep -c "Imported successfully")
    
        if [ "$importState" -eq "1" ];then
            ynh_print_info "Template Yunohost imported !"
        else
            ynh_print_warn "Template Yunohost not imported !"
        fi
    else
        ynh_print_warn "Admin user cannot connect interface !"
    fi
}

link_template(){
    #apply template to host
    tokenapi=$(curl --noproxy $domain -k -s --resolve $domain:443:127.0.0.1 --header "Content-Type: application/json" --request POST --data '{ "jsonrpc": "2.0","method": "user.login","params": {"user": "Admin","password": "zabbix"},"id": 1,"auth": null}' "${zabbixFullpath}/api_jsonrpc.php" | jq -r '.result')
    zabbixHostID=$(curl --noproxy $domain -k -s --resolve $domain:443:127.0.0.1 --header "Content-Type: application/json" --request POST --data '{"jsonrpc":"2.0","method":"host.get","params":{"filter":{"host":["Zabbix server"]}},"auth":"'"$tokenapi"'","id":1}' "${zabbixFullpath}/api_jsonrpc.php" | jq -r '.result[0].hostid')
    zabbixTemplateID=$(curl --noproxy $domain -k -s --resolve $domain:443:127.0.0.1 --header "Content-Type: application/json" --request POST --data '{"jsonrpc":"2.0","method":"template.get","params":{"filter":{"host":["Template Yunohost"]}},"auth":"'"$tokenapi"'","id":1}' "${zabbixFullpath}/api_jsonrpc.php" | jq -r '.result[0].templateid')
    applyTemplate=$(curl --noproxy $domain -k -s --resolve $domain:443:127.0.0.1 --header "Content-Type: application/json" --request POST --data '{"jsonrpc":"2.0","method":"host.massadd","params":{"hosts":[{"hostid":"'"$zabbixHostID"'"}],"templates":[{"templateid":"'"$zabbixTemplateID"'"}]},"auth":"'"$tokenapi"'","id":1}' "${zabbixFullpath}/api_jsonrpc.php" | jq -r '.result.hostids[]')
    if [ "$applyTemplate" -eq "$zabbixHostID" ];then
        ynh_print_info "Template Yunohost linked to Zabbix server !"
    else
        ynh_print_warn "Template Yunohost no linked to Zabbix server !"
    fi

}

check_proc_zabbixserver(){
    pgrep zabbix_server >/dev/null
    if [ $? -eq 0 ];then
        ynh_print_info "zabbix server is started !"
    else
        ynh_print_err "Zabbix Server not started, try to start it with the yunohost interface."
        ynh_print_err "If Zabbix Server can't start, please open a issue on https://github.com/YunoHost-Apps/zabbix_ynh/issues"
    fi
}

check_proc_zabbixagent(){
   pgrep zabbix_agentd >/dev/null
   if [ $? -eq 0 ];then
       ynh_print_info "zabbix agent is started"
   else
       ynh_print_err "Zabbix agent not started, try to start it with the yunohost interface."
       ynh_print_err "If Zabbix agent can't start, please open a issue on https://github.com/YunoHost-Apps/zabbix_ynh/issues"
   fi
}

install_zabbix_repo(){
    ynh_add_extra_apt_repos__3_path=$(find /var/cache/yunohost/ /etc/yunohost/apps/zabbix/ -name "ynh_add_extra_apt_repos__3" | tail -n 1)
    source "$ynh_add_extra_apt_repos__3_path"
    ynh_install_extra_repo --repo="http://repo.zabbix.com/zabbix/4.2/debian $(lsb_release -sc) main" --key=https://repo.zabbix.com/zabbix-official-repo.key  --priority=999  --name=zabbix
    ynh_package_install zabbix-release
}