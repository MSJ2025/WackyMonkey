# res://scenes/peanut.gd
extends Area2D

signal collected(peanut_node)

func _ready() -> void:
    # Assure-toi que Monitoring est actif et qu'il y a un CollisionShape2D enfant
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody2D:
        # Émet le signal en passant self, pour que Main puisse
        # queue_free() la cacahuète au bon moment et appliquer le buff
        emit_signal("collected", self)
