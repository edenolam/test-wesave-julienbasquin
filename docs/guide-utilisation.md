# Guide d’utilisation

Le [README](../README.md) décrit l’installation avec `make setup`.
Ce guide détaille les essais dans Swagger et les commandes de développement.

## Se connecter dans Swagger

Ouvrir http://localhost:3000/docs/index.html après le démarrage.


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
5. Cliquer **Authorize** en haut de la page, coller uniquement le jeton
   (sans le préfixe `Bearer`),
   valider avec **Authorize**, puis fermer avec **Close**.

Le jeton expire après 24 heures et n’est pas conservé au rechargement de Swagger.
Les champs sous **Responses / Example Value** décrivent le contrat ; le résultat
réel d’une requête est sous **Server response / Response body**.

## Parcours de vérification

Pour chaque étape, utiliser **Try it out**, remplir les paramètres puis **Execute**.

| Étape | Endpoint | Paramètres et résultat attendu |
| --- | --- | --- |
| Lister les portefeuilles | GET /api/v1/portfolios | `offset = 0` : trois portefeuilles préparés, réponse 200 |
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

Sur une installation neuve, les données comprennent trois profils (Épargne diversifiée, Profil prudent,
Profil dynamique), 18 achats/ventes et 91 jours calendaires de cours pour huit
actifs (ETF, actions, obligation et fonds). Les valeurs sont entièrement fictives.
`make seed` peut être relancé : il conserve les données existantes sans dupliquer
les opérations. Les valeurs affichées dépendent de la date et des cours chargés.

Pour tester les écritures sans modifier les profils préparés, créer un nouveau
portefeuille via **POST /api/v1/portfolios**, puis y enregistrer un achat via
**POST /api/v1/portfolios/{portfolio_id}/trades**. Utiliser un actif du catalogue,
une quantité et un prix positifs et une date d’exécution passée. Une vente
supérieure à la position disponible doit renvoyer **422**.

## Commandes utiles


```sh
make demo       # Parcours HTTP complet avec création de données supplémentaires
make check      # Tests, style, Brakeman et audit des dépendances
```

La démonstration crée un utilisateur unique, un portefeuille et un achat,
affiche les positions et la valorisation, puis révoque sa session.

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

## Réponses HTTP et dépannage


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
| Le serveur ne répond pas | Vérifier `make status` et `make logs` ; `/up` contrôle le démarrage de Rails, sans tester PostgreSQL |
| Swagger ne charge pas | Vérifier Internet : ses scripts viennent d’un CDN à version fixée |
| Port 3000 occupé | Libérer le port avant `make up` |
| Impossible de joindre Docker | Démarrer Docker et vérifier les permissions du socket |

Les requêtes exécutées dans Swagger modifient réellement la base locale.

