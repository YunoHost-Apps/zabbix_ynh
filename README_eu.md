<!--
Ohart ongi: README hau automatikoki sortu da <https://github.com/YunoHost/apps/tree/master/tools/readme_generator>ri esker
EZ editatu eskuz.
-->

# Zabbix YunoHost-erako

[![Integrazio maila](https://apps.yunohost.org/badge/integration/zabbix)](https://ci-apps.yunohost.org/ci/apps/zabbix/)
![Funtzionamendu egoera](https://apps.yunohost.org/badge/state/zabbix)
![Mantentze egoera](https://apps.yunohost.org/badge/maintained/zabbix)

[![Instalatu Zabbix YunoHost-ekin](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=zabbix)

*[Irakurri README hau beste hizkuntzatan.](./ALL_README.md)*

> *Pakete honek Zabbix YunoHost zerbitzari batean azkar eta zailtasunik gabe instalatzea ahalbidetzen dizu.*  
> *YunoHost ez baduzu, kontsultatu [gida](https://yunohost.org/install) nola instalatu ikasteko.*

## Aurreikuspena

A monitoring tool for diverse IT components, including networks, servers, VMs and cloud services.

**Paketatutako bertsioa:** 7.0~ynh1

## Pantaila-argazkiak

![Zabbix(r)en pantaila-argazkia](./doc/screenshots/screenshot1.png)

## Dokumentazioa eta baliabideak

- Aplikazioaren webgune ofiziala: <https://www.zabbix.com>
- Administratzaileen dokumentazio ofiziala: <https://www.zabbix.com/manuals>
- Jatorrizko aplikazioaren kode-gordailua: <https://github.com/zabbix/zabbix>
- YunoHost Denda: <https://apps.yunohost.org/app/zabbix>
- Eman errore baten berri: <https://github.com/YunoHost-Apps/zabbix_ynh/issues>

## Garatzaileentzako informazioa

Bidali `pull request`a [`testing` abarrera](https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing).

`testing` abarra probatzeko, ondorengoa egin:

```bash
sudo yunohost app install https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing --debug
edo
sudo yunohost app upgrade zabbix -u https://github.com/YunoHost-Apps/zabbix_ynh/tree/testing --debug
```

**Informazio gehiago aplikazioaren paketatzeari buruz:** <https://yunohost.org/packaging_apps>
