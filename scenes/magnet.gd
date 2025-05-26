# res://scenes/magnet.gd
extends Area2D
signal collected(magnet)

func _ready() -> void:
    # active le body_entered
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody2D:
        print("🧲 Magnet: body_entered par le joueur, j’émets collected")
        emit_signal("collected", self)
