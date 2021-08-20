* Any known limitations, constrains or stuff not working, such as (but not limited to):
    * Only x86_64 architecture is supported
    * Do not change the default admin user password. The user is disabled just after the install but he’s used to update templates.
    * The Zabbix server port is not opened by default for external monitoring (active agent).

* Other infos that people should be aware of, such as:
    * Configuration at install. SSO works. You can add your users in a group in Zabbix (for permissions/rights).
    * A Yunohost template is imported and linked to the host "Zabbix-server" (127.0.0.1) for basic monitoring for YunoHost.
