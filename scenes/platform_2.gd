# res://scenes/platform2.gd
extends StaticBody2D

@export var travel_range : float = 200.0
@export var travel_time  : float = 4.0

@export var breakable    : bool  = true
@export var persistent   : bool  = false
@export var bounce_mult  : float = 1.0      # <— nouveau

@onready var anim     : AnimatedSprite2D = $AnimatedSprite2D
@onready var col      : CollisionShape2D = $CollisionShape2D

var origin_x : float

func set_breakable(b: bool) -> void:
    breakable = b

func set_persistent(p: bool) -> void:
    persistent = p

func set_bounce_mult(b: float) -> void:
    bounce_mult = b

func get_bounce_mult() -> float:
    return bounce_mult

func _ready() -> void:
    origin_x = global_position.x

func _start_moving_horizontal() -> void:
    var screen_w = get_viewport_rect().size.x
    var tw = create_tween().set_loops()
    tw.tween_property(self, "global_position:x",
        origin_x + screen_w * 0.5, travel_time * 0.5)
    tw.tween_property(self, "global_position:x",
        origin_x - screen_w * 0.5, travel_time * 0.5)

func _start_moving_vertical() -> void:
    var origin_y = global_position.y
    var screen_h = get_viewport_rect().size.y
    var tw = create_tween().set_loops()
    tw.tween_property(self, "global_position:y",
        origin_y + screen_h * 0.5, travel_time * 0.5)
    tw.tween_property(self, "global_position:y",
        origin_y - screen_h * 0.5, travel_time * 0.5)

func break_platform() -> void:
    if not breakable:
        return
    col.disabled = true
    anim.play("break")
    await anim.animation_finished
    if persistent:
        return
    var fade = create_tween()
    fade.tween_property(anim, "modulate:a", 0.0, 0.5)
    fade.tween_callback(Callable(self, "queue_free"))
