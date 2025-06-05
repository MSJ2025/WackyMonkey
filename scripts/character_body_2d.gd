# res://scripts/character_body_2d.gd
extends CharacterBody2D

@export var speed      : float = 210.0
@export var jump_force : float = 1500.0
@export var gravity    : float = 2500.0

@onready var anim     : AnimatedSprite2D  = $AnimatedSprite2D
@onready var col_jump : CollisionShape2D  = $Collisionjump
@onready var col_fly  : CollisionShape2D  = $Collisionfly
@onready var jump_sound : AudioStreamPlayer2D = $JumpSound

var was_on_floor : bool = false
var rebound_cooldown : float = 0.0

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
    velocity.y += gravity * delta

    var dir_x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    if right_touch_count > 0:
        dir_x += 1
    if left_touch_count > 0:
        dir_x -= 1
    velocity.x = dir_x * speed

    # -------- Correction rebond --------
    if rebound_cooldown > 0.0:
        rebound_cooldown -= delta

    var did_rebound = false

    # On NE rebondit que quand on tombe !
    if rebound_cooldown <= 0.0 and velocity.y > 0:
        for i in range(get_slide_collision_count()):
            var collision = get_slide_collision(i)
            if collision.get_normal().y < -0.7:
                var collider = collision.get_collider()
                var bounce_multiplier = 1.0
                if collider.has_method("break_platform"):
                    collider.call("break_platform")
                if collider.has_method("get_bounce_mult"):
                    bounce_multiplier = collider.call("get_bounce_mult")
                velocity.y = -jump_force * bounce_multiplier
                anim.play("jump")
                if jump_sound.playing:
                    jump_sound.stop()
                jump_sound.play()
                update_collision_shape()
                rebound_cooldown = 0.12
                did_rebound = true
                break

    move_and_slide()

    var vw = get_viewport_rect().size.x
    if global_position.x > vw:
        global_position.x -= vw
    elif global_position.x < 0:
        global_position.x += vw

    if not anim.is_playing() and not did_rebound:
        anim.play("fly")
        update_collision_shape()

func update_collision_shape() -> void:
    col_jump.disabled = anim.animation != "jump"
    col_fly.disabled  = anim.animation != "fly"
