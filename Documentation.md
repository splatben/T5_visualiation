# App for viewing of 3D model with tilt Five

## Addon 

 * ``TiltFiveGodot4`` [gitHub](https://github.com/GodotVR/TiltFiveGodot4?tab=readme-ov-file), disponible sur le partage d'asset en ligne de godot
 * ``TiltFiveTools`` [gitHub](https://github.com/GodotVR/TiltFiveTools/blob/main/project.gd/addons/tiltfive_tools/README.md#general-concepts)

## Code appris

doc methode:
`T5ToolsPlayer.find_instance(self).get_origin()` : recupérer le "plateau" instance de T5Origin3D
`get_parent()` : recupérer le node parent 

doc class :

`T5Controlleur3D` : le "bâton"
signal: `nom_signal(infoEnvoyé : typeInfo)`
	`button_pressed(name : String)`des buttons de 1 à 3 et trigger click quand appuyer
	`button_released(name : String)`des buttons de 1 à 3 et trigger click quand relacher
	`input_float_changed(name : String, value : float)` gachette analogique
	`input_vector2_changed(name : String, value : Vector2)` stick
`T5Origin3D` : le "plateau", l'origin de l'espace 3D 

Pour utiliser de la 2D utiliser le script `viewport2D3D.gd` dans l'addon tiltfiveTool dans un node 3d
Pour pouvoir select un node avec le pointeur -> mettre boite de colision et mettre bon layer 
