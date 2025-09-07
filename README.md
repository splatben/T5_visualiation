# 🎲 Tilt Five Godot Demo

![Godot](https://img.shields.io/badge/Godot-4.x-blue?logo=godot-engine)
![Tilt Five](https://img.shields.io/badge/Tilt%20Five-AR-yellow?logo=tilt-five)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
  
Cette aplication a été réaliser dans le contexte du projet [Digitalis](https://digitalis.humanities.science/) et d'un stage de 8 semaine au [Centre Image de l'URCA](https://centreimage.univ-reims.fr/).L'application à pour bût d'être une démonstration de ce qui est réalisable pour de la visualisation d'objet 3D avec les lunettes de réalité augmenté [TiltFive](https://www.tiltfive.com/).

## 👤 Auteur

- **Stagiaire** : Benoit Collot, 8 semaine avril-juin 2025
- **Encadrants** : Stéphanie Prévost, Hervé Deleau

## 📦 À quoi sert ce projet ?

Ce projet est une application interactive pour Tilt Five, développée avec Godot 4.  
Il permet de manipuler des objets 3D sur le plateau Tilt Five, d’ajouter des annotations, de charger et sauvegarder des modèles, et d’interagir avec la scène en réalité augmentée via la baguette Tilt Five.

## 🚀 Fonctionnalités principales

- **Manipulation d’objets 3D**
  - Sélectionner un objet avec la gâchette du wand.
  - Déplacer un objet sélectionné avec le pointeur laser.
  - Tourner un objet sélectionné en bougeant le wand (gyroscope).
  - Agrandir (`A`) ou réduire (`Y`) un objet.
  - Réinitialiser la position et la rotation (`1`).
  - Zoomer/dézoomer la scène entière si aucun objet n’est sélectionné.

- **Annotations**
  - Ajouter une annotation sur un objet (`Stick click`).
  - Modifier une annotation existante.
  - Supprimer une annotation (`2`).
  - Verrouiller/déverrouiller une annotation (`X`).
  - Afficher/masquer le menu contextuel (`B`).

- **Chargement et sauvegarde de modèles**
  - Importer des fichiers `.glb`, `.gltf`, `.xyz`, `.ply`, `.tscn`.
  - Sauvegarder la scène et ses annotations au format `.dat`.
  - Restauration complète des objets et annotations à partir d’un fichier sauvegardé.

- **Affichage HUD**
  - Les commandes du wand sont affichées à l’écran pour guider l’utilisateur.

## 🛠️ Addons utilisés

- [TiltFiveGodot4](https://github.com/GodotVR/TiltFiveGodot4)  
  Permet l’intégration du matériel Tilt Five dans Godot.
- [TiltFiveTools](https://github.com/GodotVR/TiltFiveTools)  
  Fournit des scripts et nodes pour pointer, gérer le plateau, le menu, etc.

## 🎮 Contrôles du Wand

| Action                       | Bouton/Commande         |
|------------------------------|-------------------------|
| Sélectionner un objet        | Gâchette                |
| Déplacer l’objet             | Pointeur laser          |
| Tourner l’objet              | Gyroscope du wand       |
| Agrandir l’objet             | A                       |
| Réduire l’objet              | Y                       |
| Réinitialiser l’objet        | 1                       |
| Zoomer/Dézoomer la scène     | A / Y (sans sélection)  |
| Ajouter/Modifier annotation  | Stick click             |
| Verrouiller annotation       | X                       |
| Supprimer annotation         | 2                       |
| Afficher/Masquer le menu     | B                       |

## 🏁 Comment utiliser ce projet ?

1. **Installer Godot 4** et les addons [TiltFiveGodot4](https://github.com/GodotVR/TiltFiveGodot4) et [TiltFiveTools](https://github.com/GodotVR/TiltFiveTools).
2. **Cloner ce dépôt** et ouvrir le projet dans Godot.
3. **Lancer la scène principale** : `StartScene.tscn`.
4. **Brancher le Tilt Five** et utiliser le wand pour manipuler les objets sur le plateau.
5. **Charger des modèles** via le menu, ajouter des annotations, et sauvegarder votre travail.

## ⚠️ Remarques

- Certains modèles `.tscn` peuvent présenter des bugs de collision ce chargement est principalement pour du debug ou des test, vous devez definir la boite de collisions vous mem dans godot.
- Le menu HUD affiche les commandes disponibles et les actions possibles.
- Les signaux globaux (`glasses_connected`, `new_comment`, `comment_delete`) facilitent la communication entre les différents scripts ``Player_control.gd`` et ``SceneT5.gd``.

## 📄 License

Ce projet est sous licence MIT.  
Voir le fichier `LICENSE` pour plus d’informations.

## 🤝 Contribuer

Les contributions, issues et suggestions sont les bienvenues !  
N’hésitez pas à ouvrir une issue ou une pull request.

*Made with ❤️ using [Godot Engine](https://godotengine.org/) & [Tilt Five](https://www.tiltfive.com/)*
