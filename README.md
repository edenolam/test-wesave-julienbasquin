# API de portefeuilles d’investissement

API Ruby on Rails réalisée pour le test WeSave. La consigne étant ouverte,
le périmètre retenu est celui des portefeuilles d’investissement : achats et
ventes, positions détenues et valorisation historique.

**Ruby 3.3 · Rails 8.1 API · PostgreSQL 17 · Docker Compose · Minitest**

## Démarrer

Prérequis : Docker démarré, Docker Compose 2.20+, GNU Make, port 3000 libre et
accès Internet pour les dépendances et les scripts Swagger. Ruby et PostgreSQL
s’exécutent dans Docker.

```sh
git clone https://github.com/edenolam/test-wesave-julienbasquin.git
cd test-wesave-julienbasquin
make setup
```

Avec un ZIP, extraire l’archive et lancer `make setup` dans le dossier du projet.
La commande prépare la base, charge les données fictives et attend le démarrage
de Rails. Aucun fichier de configuration supplémentaire n’est nécessaire.

**Swagger : http://localhost:3000/docs/index.html**

## Essayer l’API

Dans Swagger, exécuter **POST /api/v1/session** avec :

```json
{
  "session": {
    "email": "demo@example.test",
    "password": "Demonstration-12345!"
  }
}
```

Copier le `token` reçu dans **Authorize**, sans ajouter `Bearer`. Exécuter ensuite
**GET /api/v1/portfolios** avec `offset = 0` : trois portefeuilles sont préparés.
Utiliser un identifiant retourné pour consulter ses positions, ses opérations
ou sa valorisation. Le jeu de données comprend 8 actifs, 18 achats/ventes et
91 jours de cours fictifs sur une installation neuve.

Le [guide d’utilisation](docs/guide-utilisation.md) détaille le parcours Swagger,
les résultats attendus et le dépannage.

## Vérifier et arrêter

```sh
make demo       # Parcours HTTP complet, avec création de données supplémentaires
make check      # Tests, style, Brakeman et audit des dépendances
make down       # Arrêter les services en conservant les données
make help       # Toutes les commandes
```

`make demo` se termine par « Démonstration HTTP réussie » et ne connecte pas
Swagger. Les tests utilisent une base distincte, sans données de démonstration.
GitHub Actions exécute aussi les tests et les analyses.

## Choix techniques

- Positions calculées depuis les achats et ventes, sans duplication des quantités.
- Valeurs en `decimal(24,8)`, validations Rails et contraintes PostgreSQL.
- Contrôle chronologique des opérations et verrou par portefeuille pour empêcher
  deux ventes concurrentes de dépasser la position disponible.
- Valorisation avec le dernier cours connu à la date demandée ; si un cours manque,
  `value` vaut `null` et `missing_asset_ids` indique les actifs concernés.
- Mots de passe hachés avec bcrypt, jetons Bearer stockés sous forme d’empreinte,
  expiration après 24 heures et accès limité aux portefeuilles du propriétaire.

La [modélisation](docs/modelisation.md) explique les relations et les règles métier.
Le [contrat OpenAPI](public/docs/openapi.json) décrit les 12 opérations exposées.
Les modèles se trouvent dans `app/models`, les endpoints dans
`app/controllers/api/v1` et les tests dans `test/integration` et `test/models`.

## Limites

EUR uniquement, sans frais, fiscalité, dividendes, gestion des espèces ni calcul
de performance. Le catalogue et les cours sont alimentés par les seeds ; aucun
fournisseur de cours externe n’est connecté. Les anciens modèles `Wallet` et
`Operation` ne sont plus exposés par l’API.

Docker Compose et le compte de démonstration sont destinés à un usage local.
Avant une mise en production : HTTPS, secrets externes, sauvegardes vérifiées,
surveillance et limitation des connexions partagée entre processus restent à
mettre en place. Les scripts Swagger sont chargés depuis un CDN à version fixée.
