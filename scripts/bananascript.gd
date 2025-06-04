extends StaticBody2D

signal collected(bonus_node)

func _ready() -> void:
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody2D:
        emit_signal("collected", self)
        queue_free()
