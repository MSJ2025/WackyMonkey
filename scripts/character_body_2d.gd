# res://scripts/character_body_2d.gd
extends CharacterBody2D

@export var speed      : float = 210.0
@export var jump_force : float = 1500.0
@export var gravity    : float = 2500.0

@onready var anim     : AnimatedSprite2D  = $AnimatedSprite2D
@onready var col_jump : CollisionShape2D  = $Collisionjump
@onready var col_fly  : CollisionShape2D  = $Collisionfly

var was_on_floor : bool = false

# Pour détection fluide multi-touch
var left_touch_count := 0
var right_touch_count := 0

func _unhandled_input(event):
    if event is InputEventScreenTouch:
        var half_x = get_viewport_rect().size.x / 2.0
        if event.pressed:
            if event.position.x > half_x:
                right_touch_count += 1
            else:
                left_touch_count += 1
        else:
            if event.position.x > half_x:
                right_touch_count = max(right_touch_count - 1, 0)
            else:
                left_touch_count = max(left_touch_count - 1, 0)

func _physics_process(delta: float) -> void:
    # 1) Applique la gravité
    velocity.y += gravity * delta

    # 2) Mouvement horizontal (clavier + tactile)
    var dir_x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    if right_touch_count > 0:
        dir_x += 1
    if left_touch_count > 0:
        dir_x -= 1
    velocity.x = dir_x * speed

    # 3) Rebond + détection de plateforme “cassable” + bounce_mult
    var on_floor = is_on_floor()
    if on_floor and not was_on_floor:
        var bounce_multiplier := 1.0
        for i in range(get_slide_collision_count()):
            var kc = get_slide_collision(i)
            var collider = kc.get_collider()
            if collider.has_method("break_platform"):
                collider.call("break_platform")
            if collider.has_method("get_bounce_mult"):
                bounce_multiplier = collider.call("get_bounce_mult")
            break
        velocity.y = -jump_force * bounce_multiplier
        anim.play("jump")
        update_collision_shape()
    was_on_floor = on_floor

    move_and_slide()

    if not anim.is_playing():
        anim.play("fly")
        update_collision_shape()

func update_collision_shape() -> void:
    col_jump.disabled = anim.animation != "jump"
    col_fly.disabled  = anim.animation != "fly"
