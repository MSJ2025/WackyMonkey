# res://scripts/Splash.gd
extends Control

@export var next_scene_path : String = "res://scenes/MainMenu.tscn"
@export var display_time   : float  = 5.0  # doit correspondre à la durée de votre anim

func _ready() -> void:
    # 1) démarre l’anim
    $AnimationPlayer.play("intro")
    # 2) attends la durée (display_time)
    await get_tree().create_timer(display_time).timeout
    # 3) change de scène
    var err = get_tree().change_scene_to_file(next_scene_path)
    if err != OK:
        push_error("Splash : impossible de charger %s (erreur %d)" % [next_scene_path, err])
