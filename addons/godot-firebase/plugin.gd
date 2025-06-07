@tool
extends EditorPlugin

func _enter_tree() -> void:
    add_autoload_singleton("Firebase", "res://addons/godot-firebase/firebase_analytics.gd")

func _exit_tree() -> void:
    remove_autoload_singleton("Firebase")
