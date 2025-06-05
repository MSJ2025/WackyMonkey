# res://scenes/banana.gd
extends Area2D

signal collected

func _ready() -> void:
    # Monitoring doit être actif sur l'Area2D et il lui faut un CollisionShape2D enfant.
    # Ici on connecte body_entered → _on_body_entered via un Callable.
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody2D:
        emit_signal("collected")
        queue_free()
