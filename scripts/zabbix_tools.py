#!/usr/bin/python3

import os
import sys

import yaml
from zabbix_utils import ZabbixAPI

default_user = 'Admin'
default_pwd = 'zabbix'
ynh_admin_username = 'Superadmin-Ynh'

import mysql.connector


def get_app_settings():
    setting_file = f"/etc/yunohost/apps/{app}/settings.yml"
    assert os.path.exists(setting_file), "Setting file %s does not exists ?" % setting_file
    with open(setting_file) as f:
        settings = yaml.safe_load(f)
    return settings


def get_mysql():
    return mysql.connector.connect(
        host="127.0.0.1",
        port=3306,
        database=app_settings['db_name'],
        user=app,
        password=app_settings['db_pwd'])


def get_next_id(table, field):
    """
    Get the next ID for a column of a table.
    Note this is mostly a copy of https://github.com/zabbix/zabbix/blob/7db2636af32252b381489c3fef7d128fdbfcb790/ui/include/db.inc.php#L338-L394
    translated to python
    :param table: the table
    :param field: the field
    :return: the next id for the field of the specified table
    """
    min_val = 0
    max_val = 9223372036854775807

    while True:
        with cnx.cursor() as cur:
            cur.execute(
                'SELECT i.nextid FROM ids i WHERE i.table_name = %s AND i.field_name = %s',
                (table, field)
            )
            row = cur.fetchone()

        if row is None or row[0] is None:
            with cnx.cursor() as cur:
                cur.execute(
                    f'SELECT MAX({field}) FROM {table} WHERE {field} BETWEEN %s AND %s',
                    (min_val, max_val)
                )
                row = cur.fetchone()

            if row is None or row[0] is None:
                with cnx.cursor() as cur:
                    cur.execute(
                        'INSERT INTO ids (table_name, field_name, nextid) VALUES (%s, %s, %s)',
                        (table, field, min_val)
                    )
                cnx.commit()
            else:
                with cnx.cursor() as cur:
                    cur.execute(
                        'INSERT INTO ids (table_name, field_name, nextid) VALUES (%s, %s, %s)',
                        (table, field, row[0])
                    )
                cnx.commit()
            continue
        else:
            ret1 = row[0]
            if ret1 < min_val or ret1 >= max_val:
                with cnx.cursor() as cur:
                    cur.execute(
                        'DELETE FROM ids WHERE table_name = %s AND field_name = %s',
                        (table, field)
                    )
                    continue

            with cnx.cursor() as cur:
                cur.execute(
                    'UPDATE ids SET nextid = nextid + 1 WHERE table_name = %s AND field_name = %s',
                    (table, field)
                )
            cnx.commit()

            with cnx.cursor() as cur:
                cur.execute(
                    'SELECT i.nextid FROM ids i WHERE i.table_name = %s AND i.field_name = %s',
                    (table, field)
                )
                row = cur.fetchone()

            if row is None or row[0] is None:
                # should never be here
                continue
            else:
                ret2 = row[0]
                if ret1 + 1 == ret2:
                    return ret2

    # should never be here...
    raise Exception('Something went wrong in the id generator')


def sql_create_or_update(select_query, id_params, create_query, update_query):
    with cnx.cursor() as cur:
        cur.execute(select_query)
        res = cur.fetchall()

    if res:
        column_id = res[0][0]
        if update_query:
            with cnx.cursor() as cur:
                cur.execute(update_query, {'id': column_id})
    else:
        if id_params:
            column_id = get_next_id(*id_params)

            # Then do the insert
            with cnx.cursor() as cur:
                cur.execute(create_query, {'id': column_id})
        else:
            with cnx.cursor() as cur:
                cur.execute(create_query)

    cnx.commit()


def get_api_default_auth() -> ZabbixAPI:
    api = ZabbixAPI(url=f"https://{app_settings['domain']}{app_settings['path']}")
    api.login(user=default_user, password=default_pwd)
    return api


def get_api_auth() -> ZabbixAPI:
    api = ZabbixAPI(url=f"https://{app_settings['domain']}{app_settings['path']}")
    api.login(user=ynh_admin_username, password=app_settings['zabbix_password'])
    return api


def get_disabled_group_id(api) -> int:
    disabled_group = [g for g in api.usergroup.get() if g['name'] == 'Disabled' and g['users_status'] == '1']
    if not disabled_group:
        # Create group if missing
        api.usergroup.create({
            "name": 'Disabled',
            "users": [],
            "gui_access": 1,
            "users_status": 1
        })
        disabled_group = [g for g in api.usergroup.get() if g['name'] == 'Disabled' and g['users_status'] == '1']
    return disabled_group[0]['usrgrpid']


def get_userdirectory_id():
    query = '''SELECT userdirectoryid FROM userdirectory WHERE name = 'Yunohost' '''
    with cnx.cursor() as cur:
        cur.execute(query)
        return cur.fetchone()[0]


def get_mail_media_types(api):
    mediatypes = api.mediatype.get()
    mail_media_types = [m for m in mediatypes if m['type'] == '0' and m['provider'] == "0"]
    return {int(m['mediatypeid']): m['name'] for m in mail_media_types}


def is_admin_enabled():
    query = f'''
    SELECT count(id)
    FROM `users_groups`
    INNER JOIN `users` ON users_groups.userid = users.userid
    INNER JOIN `usrgrp` ON users_groups.usrgrpid = usrgrp.usrgrpid
    WHERE users.username = '{ynh_admin_username}' and usrgrp.users_status = 1
    '''
    with cnx.cursor() as cur:
        cur.execute(query)
        return cur.fetchone()[0] == 0


def create_cli_user():
    api = get_api_default_auth()
    group_internal_id = check_or_create_internal_group(api)

    # Create user
    users = api.user.get()
    user_id_list = [u['username'] for u in users]
    if ynh_admin_username not in user_id_list:
        api.user.create({
            "username": ynh_admin_username,
            "passwd": app_settings['zabbix_password'],
            "roleid": "3",  # superadmin role
            "usrgrps": [{'usrgrpid': group_internal_id}],
        })

        # TODO we might need to handle the upgrade so use an access which was working to create the new access


def check_or_create_internal_group(api) -> int:
    """
    Ensure that the group internal exist and is correctly configured
    :param api:
    :return: the ID of the iternal group
    """
    groups = api.usergroup.get()
    internal_group = [u for u in groups if u['name'] == 'Internal']
    if internal_group:
        api.usergroup.update({
            "usrgrpid": internal_group[0]['usrgrpid'],
            "gui_access": 1,
        })
    else:
        api.usergroup.create({
            "name": 'Internal',
            "hostgroup_rights": {},
            "users": [],
            "gui_access": 1,
        })

    groups = api.usergroup.get()
    internal_group = [u for u in groups if u['name'] == 'Internal'][0]
    return internal_group['usrgrpid']


def check_or_create_roles(api, name, type) -> int:
    """
    Ensure that the roles are correctly setup. This ensures that the LDAP configuration will be correctly mapped.
    :param api:
    :return: the ID of the role
    """
    roles = api.role.get()
    role = [u for u in roles if u['name'] == name]
    if role:
        if not role[0]['readonly']:
            api.role.update({
                'roleid': role[0]['roleid'],
                "type": type,
            })
    else:
        api.role.create({
            "name": name,
            "type": type,
        })

    roles = api.role.get()
    role = [u for u in roles if u['name'] == name][0]
    return role['roleid']


def create_or_update_group(api, name, user_directory_id) -> int:
    groups = api.usergroup.get()
    group = [u for u in groups if u['name'] == name]
    if group:
        api.usergroup.update({
            "usrgrpid": group[0]['usrgrpid'],
            "name": name,
            "gui_access": 2,
            "userdirectoryid": user_directory_id,
        })
    else:
        api.usergroup.create({
            "name": name,
            "hostgroup_rights": {},
            "users": [],
            "gui_access": 2,
            "userdirectoryid": user_directory_id,
        })

    groups = api.usergroup.get()
    internal_group = [u for u in groups if u['name'] == name][0]
    return internal_group['usrgrpid']


def configure_ldap(mail_media_types):
    # Note we don't have any API for this so we need to use raw SQL

    # Configure main user directory table
    select = '''SELECT userdirectoryid FROM userdirectory WHERE name = 'Yunohost' '''
    create = '''
    INSERT INTO `userdirectory` (`userdirectoryid`, `name`, `description`, `idp_type`, `provision_status`)
    VALUES (%(id)s, 'Yunohost', 'Yunohost LDAP authentication', 1, 1)
    '''
    update = '''
    UPDATE `userdirectory`
    SET
        `description` = 'Yunohost LDAP authentication',
        `idp_type` = 1,
        `provision_status` = 1
    WHERE `userdirectory`.`userdirectoryid` = %(id)s
    '''
    sql_create_or_update(select, ('userdirectory', 'userdirectoryid'), create, update)

    # Get user directory ID
    userdirectoryid = get_userdirectory_id()

    # Configure ldap directory table
    select = '''
    SELECT userdirectory_ldap.userdirectoryid
    FROM userdirectory_ldap
    INNER JOIN userdirectory ON userdirectory.userdirectoryid = userdirectory_ldap.userdirectoryid
    WHERE userdirectory.name = 'Yunohost'
    '''
    create = f'''
    INSERT INTO `userdirectory_ldap`
        (`userdirectoryid`, `host`, `port`, `base_dn`, `search_attribute`, `bind_dn`, `bind_password`, `start_tls`, `search_filter`, `group_basedn`, `group_name`, `group_member`, `user_ref_attr`, `group_filter`, `group_membership`, `user_username`, `user_lastname`)
    VALUES
        ({userdirectoryid}, '127.0.0.1', 389, 'ou=users,dc=yunohost,dc=org', 'uid', '', '', 0, '', '', 'cn', '', '', '', 'permission', 'givenName', 'sn')
    '''
    update = '''
    UPDATE `userdirectory_ldap` SET
        `host` = '127.0.0.1',
        `port` = 389,
        `base_dn` = 'ou=users,dc=yunohost,dc=org',
        `search_attribute` = 'uid',
        `bind_dn` = '',
        `bind_password` = '',
        `start_tls` = 0,
        `search_filter` = '',
        `group_basedn` = '',
        `group_name` = 'cn',
        `group_member` = '',
        `user_ref_attr` = '',
        `group_filter` = '',
        `group_membership` = 'permission',
        `user_username` = 'givenName',
        `user_lastname` = 'sn'
    WHERE `userdirectory_ldap`.`userdirectoryid` = %(id)s
    '''
    sql_create_or_update(select, None, create, update)

    # Configure ldap media type mapping
    for id, name in mail_media_types.items():
        select = f'''
        SELECT userdirectory_media.userdirectory_mediaid
        FROM userdirectory_media
        INNER JOIN userdirectory ON userdirectory.userdirectoryid = userdirectory_media.userdirectoryid
        WHERE userdirectory.name = 'Yunohost' AND userdirectory_media.mediatypeid = {id}
        '''
        create = f'''
        INSERT INTO `userdirectory_media`
            (`userdirectory_mediaid`, `userdirectoryid`, `mediatypeid`, `name`, `attribute`, `active`, `severity`, `period`)
        VALUES (%(id)s, {userdirectoryid}, {id}, '{name}', 'mail', 0, 63, '1-7,00:00-24:00')
        '''
        update = f'''
        UPDATE userdirectory_media
        SET
          `name` = '{name}',
          `attribute` = 'mail',
          `active` = 0,
          `severity` = 63,
          `period` = '1-7,00:00-24:00'
        WHERE `userdirectory_media`.`userdirectory_mediaid` = %(id)s
        '''
        sql_create_or_update(select, ('userdirectory_media', 'userdirectory_mediaid'), create, update)


def configure_ldap_group_mapping(group_id, role_id, name, userdirectoryid):
    # Note we don't have any API for this so we need to use raw SQL

    select = f'''
    SELECT userdirectory_idpgroup.userdirectory_idpgroupid
    FROM userdirectory_idpgroup
    INNER JOIN userdirectory ON userdirectory.userdirectoryid = userdirectory_idpgroup.userdirectoryid
    WHERE userdirectory.name = 'Yunohost' AND userdirectory_idpgroup.roleid = {role_id}
    '''
    create = f'''
    INSERT INTO `userdirectory_idpgroup` (`userdirectory_idpgroupid`, `userdirectoryid`, `roleid`, `name`)
    VALUES (%(id)s, {userdirectoryid}, {role_id}, '{name}')
    '''
    update = f'''
    UPDATE userdirectory_idpgroup
    SET
        `name` = '{name}'
    WHERE `userdirectory_idpgroup`.`userdirectory_idpgroupid` = %(id)s
    '''
    sql_create_or_update(select, ('userdirectory_idpgroup', 'userdirectory_idpgroupid'), create, update)

    with cnx.cursor() as cur:
        cur.execute(select)
        userdirectory_idpgroupid = cur.fetchone()[0]

    select = f'''
    SELECT userdirectory_usrgrp.userdirectory_usrgrpid
    FROM userdirectory_usrgrp
    WHERE userdirectory_idpgroupid = {userdirectory_idpgroupid} AND userdirectory_usrgrp.usrgrpid = {group_id}
    '''
    create = f'''
    INSERT INTO `userdirectory_usrgrp` (`userdirectory_usrgrpid`, `userdirectory_idpgroupid`, `usrgrpid`)
    VALUES (%(id)s, {userdirectory_idpgroupid}, {group_id})
    '''
    update = None
    sql_create_or_update(select, ('userdirectory_usrgrp', 'userdirectory_usrgrpid'), create, update)


def enable_ldap_default(api):
    api.authentication.update({
        "authentication_type": 1,
        'ldap_auth_enabled': 1,
        'ldap_case_sensitive': 1,
        'ldap_jit_status': 1,
        'ldap_userdirectoryid': 1,
        'disabled_usrgrpid': get_disabled_group_id(api),
    })


def configure_ldap_auth():
    api = get_api_auth()
    mail_media_types = get_mail_media_types(api)

    superadmin_role_id = check_or_create_roles(api, 'Super admin role', 3)
    admin_role_id = check_or_create_roles(api, 'Admin role', 2)
    user_role_id = check_or_create_roles(api, 'User role', 1)

    configure_ldap(mail_media_types)
    user_directory_id = get_userdirectory_id()

    user_group_id = create_or_update_group(api, 'ynh-users', user_directory_id)
    admin_group_id = create_or_update_group(api, 'ynh-admins', user_directory_id)
    superadmin_group_id = create_or_update_group(api, 'ynh-superadmin', user_directory_id)

    configure_ldap_group_mapping(superadmin_group_id, superadmin_role_id, 'zabbix.superadmin', user_directory_id)
    configure_ldap_group_mapping(admin_group_id, admin_role_id, 'zabbix.admin', user_directory_id)
    configure_ldap_group_mapping(user_group_id, user_role_id, 'zabbix.main', user_directory_id)

    enable_ldap_default(api)


def disable_guest_user():
    api = get_api_auth()
    users = api.user.get(selectUsrgrps='extend')
    guest_users = [u for u in users if u['username'] == 'guest']
    disabled_group_id = get_disabled_group_id(api)
    if guest_users:
        group_param = set([g['usrgrpid'] for g in guest_users[0]['usrgrps']] + [disabled_group_id])
        group_param = [{'usrgrpid': g} for g in group_param]
        api.user.update({
            "userid": guest_users[0]['userid'],
            "usrgrps": group_param
        })


def disable_initial_admin_user():
    api = get_api_auth()
    users = api.user.get(selectUsrgrps='extend')
    admin_users = [u for u in users if u['username'] == 'Admin']
    disabled_group_id = get_disabled_group_id(api)
    if admin_users:
        group_param = set([g['usrgrpid'] for g in admin_users[0]['usrgrps']] + [disabled_group_id])
        group_param = [{'usrgrpid': g} for g in group_param]
        api.user.update({
            "userid": admin_users[0]['userid'],
            "usrgrps": group_param
        })


def configure_mediatype():
    api = get_api_auth()
    mediatypes = get_mail_media_types(api)
    for key, name in mediatypes.items():
        api.mediatype.update({
            'mediatypeid': key,
            'passwd': app_settings['mail_pwd'],
            'smtp_email': f"zabbix@{app_settings['domain']}",
            'smtp_helo': app_settings['domain'],
            'smtp_server': app_settings['domain'],
            'smtp_port': 587,
            'smtp_security': 1,
            'smtp_authentication': 1,
            'username': 'zabbix'
        })


def import_template():
    api = get_api_auth()
    with open('../conf/Template_Yunohost.xml', mode='r', encoding='utf-8') as f:
        template_source = f.read()
    api.configuration.import_(
        format="xml",
        # TODO check if this look good to update existing template and delete missing items and triggers.
        rules={
            "templates": {
                "createMissing": True,
                "updateExisting": True
            },
            "items": {
                "createMissing": True,
                "updateExisting": True,
                "deleteMissing": True
            },
            "triggers": {
                "createMissing": True,
                "updateExisting": True,
                "deleteMissing": True
            },
            "valueMaps": {
                "createMissing": True,
                "updateExisting": True,
                "deleteMissing": True
            }
        },
        source=template_source,
    )


def link_template():
    api = get_api_auth()
    # ynh_template_id = api.configuration.

    hosts = api.host.get(
        output=["hostid"],
        selectInterfaces=['type', 'ip', ],
        selectParentTemplates=["templateid", "name"])
    localhost = [h for h in hosts
                 if h['interfaces']
                 and h['interfaces'][0]['type'] == '1'
                 and h['interfaces'][0]['ip'] == '127.0.0.1']

    ynh_template = api.template.get(output=["templateids", "name"],
                                    filter={"name": ["Template Yunohost"]})

    if localhost and ynh_template:
        previous_templates_ids = set(
            [t['templateid'] for t in localhost[0]['parentTemplates']] + [ynh_template[0]['templateid']])
        previous_templates_ids = [{'templateid': t} for t in previous_templates_ids]
        api.host.update(
            hostid=localhost[0]['hostid'],
            templates=previous_templates_ids
        )


def enable_superadmin_ynh():
    if not is_admin_enabled():
        # We need to do it with SQL because when the user is disabled so we can't authenticate it
        query = f'''
        DELETE FROM users_groups WHERE id IN (
            SELECT id
            FROM `users_groups`
            INNER JOIN `users` ON users_groups.userid = users.userid
            INNER JOIN `usrgrp` ON users_groups.usrgrpid = usrgrp.usrgrpid
            WHERE users.username = '{ynh_admin_username}' and usrgrp.users_status = 1
        )
        '''
        with cnx.cursor() as cur:
            cur.execute(query)
        cnx.commit()


def disable_superadmin_ynh():
    if is_admin_enabled():
        api = get_api_auth()
        users = api.user.get()
        ynh_admin_users = [u for u in users if u['username'] == ynh_admin_username]
        disabled_group_id = get_disabled_group_id(api)
        if ynh_admin_users:
            # We need to do it with SQL because we can't disable the user itself
            column_id = get_next_id('users_groups', 'id')
            query = f'''
            INSERT INTO `users_groups` (`id` , `usrgrpid`, `userid`)
            VALUES ({column_id} ,{disabled_group_id}, {ynh_admin_users[0]['userid']})
            '''
            with cnx.cursor() as cur:
                cur.execute(query)
            cnx.commit()


app = os.environ['YNH_APP_ID']
cmd = sys.argv[1]
app_settings = get_app_settings()
cnx = get_mysql()

if cmd == 'configure_cli_user':
    create_cli_user()
elif cmd == 'configure_ldap_auth':
    configure_ldap_auth()

elif cmd == 'disable_guest_user':
    disable_guest_user()

elif cmd == 'disable_initial_admin_user':
    disable_initial_admin_user()

elif cmd == 'configure_mediatype':
    configure_mediatype()

elif cmd == 'import_template':
    import_template()

elif cmd == 'link_template':
    link_template()

elif cmd == 'enable_superadmin_ynh':
    enable_superadmin_ynh()

elif cmd == 'disable_superadmin_ynh':
    disable_superadmin_ynh()

# Close connection
cnx.close()
