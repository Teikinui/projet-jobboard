# Rôle de `auth.js`

`auth.js` sert de **pont entre les composants React et `AuthProvider`**.

Il contient généralement :

```jsx
import { createContext, useContext } from 'react'

export const AuthContext = createContext(null)

export function useAuth() {
  return useContext(AuthContext)
}
```

## Concrètement

Dans `AuthProvider.jsx`, on fournit les fonctions et les données :

```jsx
<AuthContext.Provider value={{
  user,
  loading,
  login,
  logout,
  setUser
}}>
  {children}
</AuthContext.Provider>
```

Dans un autre composant, par exemple `Login.jsx`, on les récupère grâce à `auth.js` :

```jsx
import { useAuth } from '../auth'

const { login } = useAuth()
```

Cela permet d'utiliser :

```jsx
login(credentials)
logout()
user
loading
```

## Le chemin complet

```text
AuthProvider.jsx
        ↓
AuthContext.Provider
        ↓
auth.js : useAuth()
        ↓
Login.jsx, Header.jsx, App.jsx...
```

## Ce que `auth.js` ne fait pas

`auth.js` :

- n'envoie pas de requête HTTP ;
- ne vérifie pas le mot de passe ;
- ne stocke pas le token ;
- ne communique pas directement avec le backend.

Ces responsabilités sont assurées par :

```text
api.js          → requêtes HTTP et token
AuthProvider    → état de session et fonctions login/logout
Backend         → vérification des identifiants
```

## Pourquoi l'utiliser ?

Sans `auth.js`, il faudrait écrire partout :

```jsx
import { useContext } from 'react'
import { AuthContext } from '../auth'

const auth = useContext(AuthContext)
```

Avec le hook :

```jsx
const auth = useAuth()
```

`auth.js` est donc un raccourci qui rend le code plus lisible et évite de répéter la logique d'accès au contexte.

## Schéma du fonctionnement

```text
┌──────────────────────────────┐
│ AuthProvider.jsx             │
│                              │
│ Contient :                   │
│ - user                       │
│ - loading                    │
│ - login()                    │
│ - logout()                   │
└──────────────┬───────────────┘
               │
               │ fournit les données
               ▼
┌──────────────────────────────┐
│ AuthContext.Provider         │
│                              │
│ Partage les données avec     │
│ les composants enfants       │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ auth.js                      │
│                              │
│ useAuth() utilise            │
│ useContext(AuthContext)      │
└──────────────┬───────────────┘
               │
               │ récupère user,
               │ login(), logout()
               ▼
┌──────────────────────────────┐
│ Composants React             │
│                              │
│ Login.jsx                    │
│ Header.jsx                   │
│ App.jsx                      │
└──────────────────────────────┘
```

### Exemple avec une connexion

```text
Login.jsx
    │
    │ const { login } = useAuth()
    ▼
auth.js
    │
    │ retourne login() depuis le contexte
    ▼
AuthProvider.jsx
    │
    │ appelle api('/auth/login')
    ▼
api.js
    │
    │ envoie la requête HTTP
    ▼
Backend
```

`auth.js` est donc situé entre les composants React et `AuthProvider`, mais il ne réalise pas lui-même la connexion.
