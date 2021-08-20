* Toutes les limitations, contraintes ou éléments ne fonctionnant pas, tels que (mais sans s'y limiter) :
     * Seule l'architecture x86_64 est prise en charge
     * Ne modifiez pas le mot de passe de l'utilisateur administrateur par défaut. L'utilisateur est désactivé juste après l'installation mais il est utilisé pour mettre à jour les modèles.
     * Le port du serveur Zabbix n'est pas ouvert par défaut pour la surveillance externe (agent actif).

* D'autres informations que les gens devraient connaître, telles que :
     * Configuration à l'installation. L'authentification SSO fonctionne. Vous pouvez ajouter vos utilisateurs dans un groupe dans Zabbix (pour les autorisations/droits).
     * Un modèle Yunohost est importé et lié à l'hôte "Zabbix-server" (127.0.0.1) pour la surveillance de base de YunoHost.