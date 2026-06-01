# Contrat API Backend — Phase 2

> Ce document décrit ce que le frontend Flutter attend du backend Django.
> À partager avec le dev backend dès le début du projet.
> Le frontend utilise des mocks jusqu'à ce que ces endpoints soient disponibles.

**Base URL :** `http://[HOST]/api/v1`
**Auth :** Bearer JWT dans le header `Authorization`
**Format :** JSON, snake_case

---

## Authentification (Phase 1 — pour référence)

```
POST /auth/login/
POST /auth/otp/verify/
POST /auth/refresh/
POST /auth/logout/
```

---

## Dashboard

### GET /dashboard/summary/

Retourne le résumé complet de l'agent connecté.

**Response 200 :**
```json
{
  "agent_code": "AGT-0042",
  "agent_name": "Koné Moussa",
  "total_balance": 485000.0,
  "benefits": {
    "today": 12500.0,
    "week": 87300.0,
    "month": 312000.0,
    "total": 1250000.0
  },
  "balances": [
    {
      "operator_code": "OM",
      "operator_name": "Orange Money",
      "phone_number": "0701234567",
      "balance": 250000.0,
      "is_low": false,
      "alert_threshold": 50000.0,
      "last_updated": "2024-01-15T14:30:00Z"
    }
  ],
  "transaction_count_today": 8
}
```

---

## Gestion des puces (SIM)

### GET /sims/

Liste toutes les puces de l'agent.

**Response 200 :**
```json
{
  "results": [
    {
      "id": "sim_001",
      "operator_code": "OM",
      "operator_name": "Orange Money",
      "phone_number": "0701234567",
      "balance": 250000.0,
      "is_active": true,
      "alert_threshold": 50000.0,
      "added_at": "2024-01-10T09:00:00Z"
    }
  ]
}
```

### POST /sims/

Ajouter une nouvelle puce.

**Request body :**
```json
{
  "operator_code": "MOOV",
  "phone_number": "0601234567"
}
```

**Response 201 :** objet SIM créé (même structure que GET)

**Erreurs :**
```json
{ "error": "phone_already_registered", "message": "Ce numéro est déjà enregistré" }
{ "error": "max_sims_reached", "message": "Maximum 5 puces par agent" }
```

### PATCH /sims/{id}/

Modifier une puce (numéro ou seuil d'alerte).

**Request body :**
```json
{
  "phone_number": "0701234568",
  "alert_threshold": 75000.0
}
```

### PATCH /sims/{id}/toggle/

Activer ou désactiver une puce.

**Request body :**
```json
{ "is_active": false }
```

**Response 200 :** objet SIM mis à jour

---

## Mise à jour des soldes

### PATCH /sims/{id}/balance/

Mettre à jour manuellement le solde d'une puce.

**Request body :**
```json
{
  "balance": 320000.0,
  "updated_at": "2024-01-15T15:00:00Z"
}
```

**Response 200 :**
```json
{
  "id": "sim_001",
  "operator_code": "OM",
  "balance": 320000.0,
  "previous_balance": 250000.0,
  "is_low": false,
  "updated_at": "2024-01-15T15:00:00Z"
}
```

### GET /sims/{id}/balance-history/

Historique des 10 dernières mises à jour de solde.

**Response 200 :**
```json
{
  "results": [
    {
      "balance": 320000.0,
      "previous_balance": 250000.0,
      "updated_at": "2024-01-15T15:00:00Z"
    }
  ]
}
```

---

## Alertes

### GET /alerts/

Liste des configurations d'alerte de l'agent.

**Response 200 :**
```json
{
  "results": [
    {
      "operator_code": "OM",
      "is_enabled": true,
      "threshold": 50000.0,
      "last_updated": "2024-01-15T10:00:00Z"
    }
  ]
}
```

### PUT /alerts/{operator_code}/

Créer ou mettre à jour la config d'alerte pour un opérateur.

**Request body :**
```json
{
  "is_enabled": true,
  "threshold": 75000.0
}
```

**Response 200 :** objet AlertConfig mis à jour

---

## Codes d'erreur standard

| Code HTTP | Signification Flutter |
|---|---|
| 200 | Succès |
| 201 | Créé avec succès |
| 400 | Données invalides → `ValidationFailure` |
| 401 | Token expiré → redirect vers login |
| 403 | Non autorisé → `AuthFailure` |
| 404 | Ressource introuvable → `ServerFailure` |
| 500 | Erreur serveur → `ServerFailure` |

**Format d'erreur standard :**
```json
{
  "error": "error_code_snake_case",
  "message": "Message lisible en français pour l'affichage"
}
```

---

## Notes importantes pour le dev backend

1. **Tous les montants en FCFA** — entier ou float, jamais de string
2. **Toutes les dates en ISO 8601 UTC** — le frontend formate côté client
3. **Pagination** — utiliser `{ "count": N, "results": [...] }` (standard DRF)
4. **operator_code** — valeurs attendues : `"OM"`, `"MOOV"`, `"TELECEL"`, `"MTN"`, `"WAVE"`, `"CORIS"`
5. **CORS** — autoriser le domaine de dev Flutter web si nécessaire
6. **Authentification** — JWT avec access token (15 min) + refresh token (7 jours)
