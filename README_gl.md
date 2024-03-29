<!--
NOTA: Este README foi creado automáticamente por <https://github.com/YunoHost/apps/tree/master/tools/readme_generator>
NON debe editarse manualmente.
-->

# Zabbix para YunoHost

[![Nivel de integración](https://dash.yunohost.org/integration/zabbix.svg)](https://dash.yunohost.org/appci/app/zabbix) ![Estado de funcionamento](https://ci-apps.yunohost.org/ci/badges/zabbix.status.svg) ![Estado de mantemento](https://ci-apps.yunohost.org/ci/badges/zabbix.maintain.svg)

[![Instalar Zabbix con YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=zabbix)

*[Le este README en outros idiomas.](./ALL_README.md)*

> *Este paquete permíteche instalar Zabbix de xeito rápido e doado nun servidor YunoHost.*  
> *Se non usas YunoHost, le a [documentación](https://yunohost.org/install) para saber como instalalo.*

## Vista xeral

A monitoring tool for diverse IT components, including networks, servers, VMs and cloud services.

**Versión proporcionada:** 5.0.41~ynh1

## Capturas de pantalla

![Captura de pantalla de Zabbix](./doc/screenshots/screenshot1.png)

## Avisos / información importante

#### Known limitations or important informations

* Only x86_64 architecture is supported
* Single sign-on is supported
* Do not change the default admin user password. The user is disabled just after the install but is used to update templates.
* The Zabbix server port is not opened by default for external monitoring (active agent).
* You can add your users in a group in Zabbix (for permissions/rights).
* A YunoHost template is imported and linked to the host "Zabbix-server" (127.0.0.1) for basic monitoring for YunoHost.

## Documentación e recursos

- Web oficial da app: <https://www.zabbix.com>
- Documentación oficial para admin: <https://www.zabbix.com/manuals>
- Repositorio de orixe do código: <https://github.com/zabbix/zabbix>
- Tenda YunoHost: <https://apps.yunohost.org/app/zabbix>
- Informar dun problema: <https://github.com/YunoHost-Apps/zabbix_ynh/issues>

## Info de desenvolvemento

Envía a túa colaboración á [rama `testing`](https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing).

Para probar a rama `testing`, procede deste xeito:

```bash
sudo yunohost app install https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing --debug
ou
sudo yunohost app upgrade zabbix -u https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing --debug
```

**Máis info sobre o empaquetado da app:** <https://yunohost.org/packaging_apps>
