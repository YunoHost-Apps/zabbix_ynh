[![Integration level](https://dash.yunohost.org/integration/zabbix.svg)](https://dash.yunohost.org/appci/app/zabbix)
[![Install zabbix with YunoHost](https://install-app.yunohost.org/install-with-yunohost.png)](https://install-app.yunohost.org/?app=zabbix)
> *This package allow you to install zabbix quickly and simply on a YunoHost server.  
If you don't have YunoHost, please see [here](https://yunohost.org/#/install) to know how to install and enjoy it.*

## Overview
Zabbix integration to Yunohost.
Zabbix is a great product to monitor your equipement, include your YunoHost server.

## Configuration

Configuration at install. SSO works. You can add your users in a group in Zabbix (for permissions/rights).

## Documentation

See official documentation of Zabbix at https://www.zabbix.com/manuals(https://www.zabbix.com/manuals)

#### Multi-users support

Are LDAP auth supported

#### Supported architectures

Only Debian - Stretch 64b supported actually.

## Limitations
Do not change admin password.

## Additional information

* Do not change the default admin user password. The user is disabled juste after the install but used to update templates.
* The Zabbix server port is not opened by default for external monitoring (active agent).
* Install or update apply a template yunohost on the host "Zabbix-server" (127.0.0.1) for basic monitoring for Yunohost.
* If you want more information about Yunohost in the template, please open an issue on git.

**More information on the documentation page:**  
https://yunohost.org/packaging_apps

## LICENSE
GNU AFFERO GENERAL PUBLIC LICENSE Version 3

got to https://framagit.org/Mickael-Martin/zabbix_ynh/blob/master/LICENSE

## Links

 * Report a bug: https://framagit.org/Mickael-Martin/zabbix_ynh/issues
 * YunoHost website: https://yunohost.org/
