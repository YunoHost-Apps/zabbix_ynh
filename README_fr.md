# Zabbix pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/zabbix.svg)](https://dash.yunohost.org/appci/app/zabbix) ![](https://ci-apps.yunohost.org/ci/badges/zabbix.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/zabbix.maintain.svg)  
[![Installer Zabbix avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=zabbix)

*[Read this readme in english.](./README.md)*
*[Lire ce readme en français.](./README_fr.md)*

> *Ce package vous permet d'installer Zabbix rapidement et simplement sur un serveur YunoHost.
Si vous n'avez pas YunoHost, regardez [ici](https://yunohost.org/#/install) pour savoir comment l'installer et en profiter.*

## Vue d'ensemble

Un outil pour monitorer des réseaux, des serveurs, des VMs et autres services en ligne

**Version incluse :** 4.4~ynh1

**Démo :** https://demo.example.com

## Avertissements / informations importantes

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

## Documentations et ressources

* Site officiel de l'app : https://example.com
* Documentation officielle utilisateur : https://www.zabbix.com/manuals
* Documentation officielle de l'admin : https://yunohost.org/packaging_apps
* Dépôt de code officiel de l'app : https://framagit.org/Mickael-Martin/zabbix_ynh
* Documentation YunoHost pour cette app : https://yunohost.org/app_zabbix
* Signaler un bug : https://github.com/YunoHost-Apps/zabbix_ynh/issues

## Informations pour les développeurs

Merci de faire vos pull request sur la [branche testing](https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing).

Pour essayer la branche testing, procédez comme suit.
```
sudo yunohost app install https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing --debug
ou
sudo yunohost app upgrade zabbix -u https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing --debug
```

**Plus d'infos sur le packaging d'applications :** https://yunohost.org/packaging_apps