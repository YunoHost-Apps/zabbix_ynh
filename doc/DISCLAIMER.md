* Any known limitations, constrains or stuff not working, such as (but not limited to):
    * Configuration at install. SSO works. You can add your users in a group in Zabbix (for permissions/rights).
    * Only Debian - Stretch 64b supported actually.
    * Do not change the default admin user password. The user is disabled juste after the install but used to update templates.
    * The Zabbix server port is not opened by default for external monitoring (active agent).
    * A Yunohost template is imported and linked to the host "Zabbix-server" (127.0.0.1) for basic monitoring for YunoHost.
    * If you want more information about Yunohost in the template, please open an issue on git.

* Other infos that people should be aware of, such as:
    * any specific step to perform after installing (such as manually finishing the install, specific admin credentials, ...)
    * how to configure / administrate the application if it ain't obvious
    * upgrade process / specificities / things to be aware of ?
    * security considerations ?
