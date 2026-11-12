# API de portefeuilles d’investissement

Projet de candidature réalisé en Ruby on Rails, en réponse à la consigne
« modélisation API gestion de portefeuille ». Le portefeuille d’investissement
est une hypothèse métier du candidat ; ce périmètre n’est pas une spécification
validée par WeSave.

L’API permet de créer des portefeuilles privés, enregistrer des achats et ventes,
consulter les positions et calculer une valorisation historique.
**Swagger est l’interface de consultation et de test ; aucun tableau de bord
client n’est inclus.**

Ruby 3.3 · Rails 8.1 API · PostgreSQL 17 · Docker Compose · Minitest.

## 1. Démarrer après extraction du ZIP

Prérequis : Docker démarré, Docker Compose v2 ou supérieur, GNU Make et port 3000
libre. Ouvrir un terminal dans le dossier contenant `Makefile` et `compose.yaml`.
Aucune installation locale de Ruby ou PostgreSQL, aucun compte Heroku ou
Hostinger et aucun fichier de secrets à demander pour cette démonstration.

```sh
make setup
make seed
```

Le premier démarrage télécharge les images et les dépendances : un accès Internet
est nécessaire. Ouvrir ensuite :

**http://localhost:3000/docs/index.html**

Si Rails est encore en cours de démarrage, patienter quelques secondes puis
recharger. `http://localhost:3000/up` doit répondre avec une page verte.

## 2. Se connecter dans Swagger

Le jeu de données crée un compte local prêt à utiliser. Aucune inscription
supplémentaire n’est nécessaire pour examiner les portefeuilles de démonstration.

1. Déplier **POST /api/v1/session**, puis cliquer **Try it out**.
2. Remplacer le corps de requête par :

```json
{
  "session": {
    "email": "demo@example.test",
    "password": "Demonstration-12345!"
  }
}
```

3. Cliquer **Execute** : la section **Server response** doit afficher **201**.
4. Copier la valeur de `token` depuis **Response body**, sans les guillemets.
5. Cliquer **Authorize** en haut de la page, coller uniquement le jeton,
   valider avec **Authorize**, puis fermer avec **Close**.

Le jeton expire après 24 heures et n’est pas conservé au rechargement de Swagger.
Les champs sous **Responses / Example Value** décrivent le contrat ; le résultat
réel d’une requête est sous **Server response / Response body**.

## 3. Parcours de vérification conseillé

Pour chaque étape, utiliser **Try it out**, remplir les paramètres puis **Execute**.

| Étape | Endpoint | Paramètres et résultat attendu |
| --- | --- | --- |
| Lister les portefeuilles | GET /api/v1/portfolios | `offset = 0` : trois portefeuilles, réponse 200 |
| Voir les quantités détenues | GET /api/v1/portfolios/{id}/positions | Utiliser un `id` obtenu à l’étape précédente : liste des positions |
| Calculer leur valeur | GET /api/v1/portfolios/{id}/valuation | Même `id`, laisser la date vide : `value` en EUR, `missing_asset_ids: []` |
| Voir les opérations | GET /api/v1/portfolios/{portfolio_id}/trades | Même identifiant, `offset = 0` : six achats/ventes par portefeuille initial |
| Explorer les actifs | GET /api/v1/assets | `offset = 0` : huit actifs fictifs |
| Voir les cours | GET /api/v1/assets/{id}/prices | Utiliser l’identifiant d’un actif ; `offset = 0` |

**Les identifiants sont attribués par la base : ne pas supposer qu’ils valent 1,
8 ou 9.** `offset` est le nombre d’éléments à ignorer, pas la taille de la page.
Une liste vide avec le code 200 est un succès, sans résultat pour cette page
ou ce compte. Un compte nouvellement créé ne possède pas les portefeuilles du
compte de démonstration.

Les données comprennent trois profils (Épargne diversifiée, Profil prudent,
Profil dynamique), 18 achats/ventes et 91 jours calendaires de cours pour huit
actifs (ETF, actions, obligation et fonds). Les valeurs sont entièrement fictives.
`make seed` peut être relancé : il conserve les données existantes sans dupliquer
les opérations. Les valeurs affichées dépendent de la date et des cours chargés.

Pour tester les écritures sans modifier les profils préparés, créer un nouveau
portefeuille via **POST /api/v1/portfolios**, puis y enregistrer un achat via
**POST /api/v1/portfolios/{portfolio_id}/trades**. Utiliser un actif du catalogue,
une quantité et un prix positifs et une date d’exécution passée. Une vente
supérieure à la position disponible doit renvoyer **422**.

## 4. Démonstration automatique et tests

```sh
make demo       # Parcours HTTP complet avec création de données supplémentaires
make check      # Tests, style, Brakeman et audit des dépendances
```

La démonstration crée un utilisateur unique, un portefeuille et un achat,
affiche les positions et la valorisation, puis révoque sa session. Elle se termine
par « Démonstration HTTP réussie ». Elle ne connecte pas automatiquement Swagger.

```sh
make test       # Tests dans une base séparée
make lint       # Vérification du style
make security   # Analyses de sécurité, avec accès Internet
make help       # Liste de toutes les commandes
make logs       # Suivre les logs ; Ctrl+C quitte les logs, pas les conteneurs
make status     # État des services
make down       # Arrêter les services en conservant les données
make up         # Les redémarrer
```

## 5. Repères pour lire le code

| Emplacement | Contenu |
| --- | --- |
| [docs/modelisation.md](docs/modelisation.md) | Relations, hypothèses et règles métier |
| [public/docs/openapi.json](public/docs/openapi.json) | Contrat OpenAPI des 12 opérations |
| app/models/ | Modèles, validations, positions et valorisation |
| app/controllers/api/v1/ | Authentification, autorisations et endpoints |
| db/migrate/ et db/schema.rb | Structure et contraintes PostgreSQL |
| db/seeds.rb | Catalogue et portefeuilles fictifs |
| test/integration/ et test/models/ | Tests HTTP, règles métier et concurrence |
| script/demo.rb | Parcours de démonstration HTTP |
| .github/workflows/ci.yml | Vérifications automatisées |
| Makefile, Dockerfile, compose.yaml | Commandes et environnement local |

## 6. Fonctionnalités et choix métier


- Inscription, connexion et déconnexion ; sessions Bearer expirant après 24 heures.
- Portefeuilles privés : toutes les consultations et écritures vérifient le propriétaire.
- Catalogue d’actifs et historique des cours, alimentés via `make seed` ou la console.
- Achats et ventes immuables, positions calculées et interdiction de vente à découvert.
- Verrou PostgreSQL par portefeuille pendant l’écriture et nouvelle validation sous
  verrou : deux ventes concurrentes ne peuvent pas dépasser la quantité disponible.
- Validation de la chronologie entière pour les trades antidatés.
- Valorisation historique avec le dernier cours connu à la date demandée.
  Un cours absent produit `value: null` et la liste `missing_asset_ids`.
- Décimaux SQL (24,8), valeurs positives et finies, contraintes SQL et clés étrangères.

Hypothèses : EUR uniquement, sans frais, fiscalité, dividendes, gestion des espèces
ou calcul de performance. Un achat enregistre un investissement ; il ne débite
pas un compte bancaire. Les cours de démonstration ne sont pas des cours réels.
L’ancien prototype de trésorerie n’est plus exposé par les routes.

Le [document de modélisation](docs/modelisation.md) contient les relations,
les règles métier, le contrat HTTP et les arbitrages.

## 7. Contrat HTTP et dépannage

Les listes paginées renvoient au maximum 50 éléments (`offset=50` pour la suite).
Les positions constituent une liste complète. Les montants et quantités JSON
sont des chaînes décimales. Les erreurs suivent `{"errors":["message"]}`.

| Code ou symptôme | Signification / action |
| --- | --- |
| 200 | Consultation réussie |
| 201 | Création réussie |
| 204 | Déconnexion réussie, sans corps de réponse |
| 400 | Vérifier les paramètres et le format de date |
| 401 | Se reconnecter et remplacer le jeton dans Authorize |
| 404 | Identifiant absent ou ressource d’un autre utilisateur |
| 422 | Validation métier refusée ; lire `errors` |
| 429 | Trop de connexions ; attendre avant de réessayer |
| GET /api/v1/users ne fonctionne pas | L’inscription est un POST à tester dans Swagger |
| `value: null` | Un cours nécessaire manque ; consulter `missing_asset_ids` |
| Swagger ne charge pas | Vérifier Internet : ses scripts viennent d’un CDN à version fixée |
| Port 3000 occupé | Libérer le port avant `make up` |
| Impossible de joindre Docker | Démarrer Docker et vérifier les permissions du socket |

Les requêtes exécutées dans Swagger modifient réellement la base locale.

## 8. Sécurité et limites de livraison


Les tests couvrent l’isolation des utilisateurs, l’expiration/révocation des
sessions, les validations, les ventes excessives et antidatées, la concurrence,
l’immutabilité et la valorisation historique. GitHub Actions exécute les tests,
le style et les analyses de sécurité.

Compose fournit un environnement de développement : API sur `127.0.0.1:3000`,
base non publiée sur l’hôte, données persistantes dans un volume. Ses identifiants
PostgreSQL sont réservés au développement. Le Dockerfile est destiné au développement.
Une mise en production demande des secrets externes, HTTPS, une politique de
sauvegarde et un stockage partagé pour la limitation des connexions, actuellement
en mémoire par processus. Les jetons doivent être transmis via HTTPS hors local.
