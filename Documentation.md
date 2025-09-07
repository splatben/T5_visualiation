# 📚 Documentation Technique — Tilt Five Godot Demo

Ce document détaille le fonctionnement interne du projet, l’organisation des scripts, la relation entre les composants, et le rôle des scènes principales.

---

## 🏗️ Architecture générale

Le projet permet la manipulation d’objets 3D et l’ajout d’annotations sur le plateau Tilt Five, en utilisant la baguette (wand) comme contrôleur principal.  
Il s’appuie sur les addons TiltFiveGodot4, TiltFiveTools et PlyReader pour l’intégration matérielle, la gestion des interactions et l’import de nuages de points.

---

## 🗂️ Structure des dossiers et principaux scripts

### **player/**

- **Player_control.gd** : Contrôleur principal du wand. Gère la sélection, manipulation, rotation (gyroscope), zoom, annotations et outline des objets.
- **hud.gd / hud.tscn** : Affichage dynamique des commandes du wand à l’écran.

### **Loader/**

- **Loader.gd** : Gestionnaire d’import de fichiers 3D (`.glb`, `.gltf`, `.xyz`, `.ply`, `.tscn`). Ajoute collisions, encapsule les objets, émet des signaux de succès/erreur.
- **Saver.gd** : Sauvegarde la scène et les annotations au format `.dat` (JSON).
- **delete_list.gd** : Maintient la liste des objets importés, permet leur suppression via l’UI.
- **print_error.gd** : Affiche le statut des opérations de chargement/sauvegarde.
- **gestion_fenetre/window.gd** : Gestion des fenêtres de dialogue pour l’UI.

### **material/Annotation/**

- **Annotation.gd / Annotation.tscn** : Script et scène pour les annotations attachées aux objets 3D (texte, position, taille, rotation).
- **bulle_dialog.glb / pointeur_bulle.glb** : Modèles 3D pour l’affichage des bulles d’annotation.

### **SceneT5/**

- **SceneT5.gd / SceneT5.tscn** : Gestionnaire central de la scène Tilt Five. Coordonne les objets, annotations et synchronise via les signaux globaux.
- **menu_annotation.gd / MenuAnnotation.tscn** : Menu contextuel pour la gestion des annotations.
- **WriteAnnotation.gd** : Script pour la saisie et modification du texte des annotations.

### **addons/**

- **tiltfive/** : Intégration matérielle Tilt Five (lunettes, wand, plateau, gestion des signaux et paramètres).
- **tiltfive_tools/** : Scripts utilitaires pour le pointer laser, le menu, la gestion du plateau, etc.
- **PlyReader/** : Importation des fichiers `.ply` (nuages de points).

---

## 🔄 Relations entre scripts

### **GlobalScope.gd** (autoload singleton)

- Centralise les signaux globaux (`glasses_connected`, `new_comment`, `comment_delete`).
- Stocke des variables partagées (format d’image, référence à la scène principale).
- Permet la communication entre scripts distants (ex : annotation ajoutée ou supprimée).

### **player/Player_control.gd**

- Gère toutes les interactions du wand.
- Émet des signaux pour la création/modification/suppression d’annotations via GlobalScope.
- Interagit avec la scène principale (`SceneT5.gd`) pour manipuler les objets.
- Met à jour le HUD (`hud.gd`) pour afficher les commandes.

### **Loader/Loader.gd & Loader/Saver.gd**

- Importent et sauvegardent les objets et annotations.
- Émettent des signaux (`is_loaded`, `load_failed`, `is_saved`) pour informer l’UI et les autres scripts.
- `delete_list.gd` écoute ces signaux pour mettre à jour la liste des objets supprimables.

### **material/Annotation/Annotation.gd**

- Gère le contenu, la position, la taille et la rotation des annotations.
- Reçoit les signaux de modification/suppression depuis `Player_control.gd` et `SceneT5.gd`.

### **SceneT5/SceneT5.gd**

- Centralise la gestion des objets et annotations sur le plateau.
- Reçoit les signaux globaux pour synchroniser les modifications.
- Coordonne l’affichage du menu d’annotation et la saisie de texte.

### **HUD et UI**

- `hud.gd` affiche dynamiquement les boutons et actions disponibles selon la configuration du wand.
- `print_error.gd` et `delete_list.gd` fournissent un retour utilisateur sur les opérations de chargement, sauvegarde et suppression.

---

## 🧩 Addons et dépendances

- **TiltFiveGodot4** : Intégration matérielle Tilt Five (lunettes, wand, plateau).
- **TiltFiveTools** : Scripts utilitaires pour le pointer laser, le menu, la gestion du plateau, etc.
- **PlyReader** : Importation des fichiers `.ply` (nuages de points).

---

## 🎬 Détail des scènes principales

### **StartScene.tscn**

- Point d’entrée du projet.
- Instancie le plateau Tilt Five, le manager Tilt Five, la caméra spectateur, et le fade d’intro.
- Charge la scène principale (`SceneT5.tscn`) et le joueur (`Player.tscn`).

### **SceneT5.tscn**

- Scène centrale pour la gestion des objets et annotations sur le plateau.
- Contient le menu d’annotation, la gestion du texte, et la synchronisation des signaux globaux.

### **Player.tscn**

- Scène du joueur, instancie le contrôleur du wand (`Player_control.gd`), le HUD, et le pointer laser.

### **MenuAnnotation.tscn**

- Menu contextuel pour la création, modification et suppression des annotations.

### **Annotation.tscn**

- Scène pour l’affichage et la gestion des annotations attachées aux objets 3D.

---

## 🔗 Exemple de flux d’utilisation

1. **Chargement d’un modèle**
   - L’utilisateur importe un fichier via le menu Loader.
   - `Loader.gd` encapsule l’objet, ajoute les collisions, et émet un signal.
   - `delete_list.gd` ajoute l’objet à la liste des objets supprimables.

2. **Manipulation d’un objet**
   - L’utilisateur sélectionne un objet avec la gâchette du wand.
   - `Player_control.gd` gère la sélection, le déplacement, la rotation (gyroscope), le zoom, etc.

3. **Ajout/édition d’annotation**
   - L’utilisateur ajoute ou modifie une annotation via le wand.
   - `Player_control.gd` émet un signal via `GlobalScope` pour créer ou modifier une annotation.
   - `Annotation.gd` gère le contenu et l’affichage de l’annotation.

4. **Sauvegarde de la scène**
   - L’utilisateur sauvegarde la scène via le menu Saver.
   - `Saver.gd` récupère tous les objets et annotations, les sérialise en JSON, et écrit le fichier.

5. **Affichage des commandes**
   - `hud.gd` affiche dynamiquement les boutons et actions disponibles selon la configuration du wand.

---

## 📌 Résumé

Ce projet propose une interface complète pour manipuler des objets 3D en réalité augmentée sur Tilt Five :  

- Import, annotation, suppression, sauvegarde et restauration d’objets.
- Contrôle intuitif via le wand (gyroscope, gâchette, boutons).
- Communication entre scripts via signaux globaux pour une synchronisation fluide.
- Interface utilisateur claire avec HUD et feedback sur les opérations.

Pour plus de détails, consulte chaque script et scène dans leur dossier respectif.
