# 🎂 Pâtisserie Orientale — App Flutter

Application mobile de gestion de stock et commandes pour pâtisseries traditionnelles.

---

## 📱 Fonctionnalités

| Écran | Description |
|-------|------------|
| **Tableau de bord** | KPIs en temps réel, bilan financier, alertes stock, dernières commandes |
| **Stock** | Gestion ingrédients, alertes seuil, recherche, barre de niveau |
| **Achats** | Réapprovisionnement, historique, total dépenses filtrable |
| **Produits** | Catalogue par catégorie + recettes (quantités pour 100 pièces) |
| **Commandes** | Création, suivi statuts, détail ingrédients requis vs stock |
| **Paramètres** | Connexion Google, sauvegarde locale/Drive |

---

## 🚀 Installation

### Prérequis
- Flutter SDK ≥ 3.0.0
- Android Studio ou VS Code avec extension Flutter
- Compte Google Cloud (pour Drive backup)

### 1. Cloner et installer
```bash
cd patisserie_app
flutter pub get
```

### 2. Configurer Google Sign-In (pour la sauvegarde Gmail/Drive)

#### a) Google Cloud Console
1. Aller sur https://console.cloud.google.com
2. Créer un projet (ex: "Patisserie App")
3. Activer **Google Drive API** et **Google Sign-In**
4. Créer des identifiants OAuth 2.0 :
   - Type : Application Android
   - Package : `com.patisserie.orientale`
   - SHA-1 : récupérer avec `cd android && ./gradlew signingReport`

#### b) Fichier google-services.json
Télécharger `google-services.json` depuis la console et le placer dans :
```
android/app/google-services.json
```

#### c) android/app/build.gradle — ajouter
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### d) android/build.gradle — ajouter dans dependencies
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

> ⚠️ **Sans cette configuration, le Sign-In Google ne fonctionnera pas.**
> L'app reste fonctionnelle en mode "continuer sans compte".

### 3. Lancer
```bash
# Mode debug
flutter run

# Build APK release
flutter build apk --release

# Build APK debug (plus simple)
flutter build apk --debug
```

L'APK sera dans : `build/app/outputs/flutter-apk/app-release.apk`

---

## 🗄️ Base de données

SQLite local, stocké dans les documents de l'application.

### Schéma
```
ingredients    — Ingrédients avec stock actuel/minimum et prix
produits       — Produits avec prix de vente et catégorie
recettes       — Quantités ingrédients par produit (pour 100 pièces)
commandes      — Commandes clients avec statut
lignes_commande — Produits par commande
achats         — Historique des achats/réapprovisionnements
```

---

## 🔧 Personnalisation

### Catégories produits
Dans `produits_screen.dart`, modifier la liste `_categories`.

### Unités ingrédients
Dans `stock_screen.dart`, modifier la liste `_unites`.

### Couleurs
Dans `theme/app_theme.dart`, modifier les constantes `AppColors`.

---

## 📋 Notes importantes

### Déduction du stock
Quand une commande passe en "**Terminée**", le stock des ingrédients est
automatiquement déduiten fonction des recettes et du nombre de pièces.

### Recettes
Les quantités dans les recettes sont définies **pour 100 pièces**.
Ex : si la recette Baklawa utilise 2 kg d'amandes pour 100 pièces,
et qu'une commande est de 50 pièces → 1 kg d'amandes sera déduit.

---

## 🐛 Bugs corrigés vs version Python/Kivy

1. ✅ Calcul CA : ne compte que les commandes `terminee`
2. ✅ Déduction stock atomique (transaction SQLite)
3. ✅ Restauration DB ferme proprement la connexion avant de copier
4. ✅ Pas de double déduction si statut changé plusieurs fois
5. ✅ Validation formulaires côté Flutter (pas juste côté DB)
6. ✅ Filtre dates correct (date() pour comparaison SQLite)

---

## 📦 Dépendances principales

| Package | Usage |
|---------|-------|
| `sqflite` | Base de données SQLite |
| `google_sign_in` | Authentification Google |
| `googleapis` | API Google Drive |
| `shared_preferences` | Préférences locales |
| `google_fonts` | Polices Playfair Display + Nunito Sans |
| `provider` | Gestion d'état |
| `path_provider` | Chemins fichiers Android/iOS |
