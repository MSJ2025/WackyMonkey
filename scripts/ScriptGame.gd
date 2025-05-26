# res://scripts/ScriptGame.gd
extends Node2D

# — PackedScenes & JSON —
@export var ground_scene       : PackedScene
@export var platform_scene     : PackedScene
@export var platform2_scene    : PackedScene
@export var banana_scene       : PackedScene
@export var peanut_scene       : PackedScene
@export var initial_platforms  : int    = 10
@export var vertical_gap       : float  = 200.0

# — État de jeu —
var level     : int        = 1
var level_cfg : Dictionary = {}

# — Génération infinie —
var highest_y      : float = 0.0
var ground_y       : float = 0.0
var initial_cam_y  : float = 0.0

# — Scores & game‐over —
var initial_player_y : float = 0.0
var best_player_y    : float = 0.0
var height_score     : int   = 0
var banana_score     : int   = 0

# — Buff cacahuète —
var _peanut_active          : bool  = false
var _player_base_speed      : float = 0.0
var _player_base_jump_force : float = 0.0

# — Nodes —
@onready var camera2d        : Camera2D          = $Camera2D
@onready var player          : CharacterBody2D   = $Player
@onready var label_score     : Label             = $CanvasLayer/LabelScore
@onready var label_banana    : Label             = $CanvasLayer/BananaScore
@onready var label_level     : Label             = $CanvasLayer/Level
@onready var banana_spawner  : Timer             = $BananaSpawner
@onready var peanut_spawner  : Timer             = $PeanutSpawner
@onready var game_over_layer : CanvasLayer       = $GameOverLayer
@onready var banana_sfx      : AudioStreamPlayer = $BananaPlayer
@onready var peanut_sfx      : AudioStreamPlayer = $PeanutPlayer
@onready var magnet_spawner : Timer = $MagnetSpawner
@onready var magnet_sfx     : AudioStreamPlayer = $MagnetPlayer
@onready var level_up_sfx : AudioStreamPlayer = $LevelUpPlayer

var _magnet_active : bool = false
var _magnet_radius : float = 0.0
var _magnet_strength : float = 0.0

func _ready() -> void:
    # → 1) charge la config JSON pour ce niveau
    level_cfg = LevelManager.get_config_for(level)
    print("▶️ ScriptGame, niveau %d, cfg :" % level, level_cfg)
    print_debug("► Level_cfg chargé pour le niveau %d : %s" % [level, level_cfg])

    # → 2) setup Game Over
    game_over_layer.visible = false
    var btn = game_over_layer.get_node_or_null("ColorRect/VBoxContainer/ReplayButton") as Button
    if btn:
        btn.connect("pressed", Callable(self, "_on_replay_pressed"))

    # → 3) création du sol, player, plateforme initiales & caméra
    _create_ground_and_player()
    _spawn_initial_platforms()

    # → 4) repères de hauteur
    initial_player_y = player.global_position.y
    best_player_y    = initial_player_y

    # → 5) scores & UI
    height_score  = 0
    banana_score  = 0
    label_score.text  = "%d m"        % height_score
    label_banana.text = "Bananes: %d" % banana_score
    label_level.text  = "Niveau: %d"  % level

    # → 6) murs et bordures
    setup_borders()

    # → 7) configure les spawners
    var bcfg = level_cfg.get("banana.tscn", {})
    banana_spawner.wait_time  = bcfg.get("spawn_interval", 2.0)
    banana_spawner.one_shot   = false
    banana_spawner.autostart  = true
    banana_spawner.connect("timeout", Callable(self, "_on_BananaSpawner_timeout"))


    var pcfg = level_cfg.get("peanut.tscn", {})
    peanut_spawner.wait_time  = pcfg.get("spawn_interval", 30.0)
    peanut_spawner.one_shot   = false
    peanut_spawner.autostart  = true
    peanut_spawner.connect("timeout", Callable(self, "_on_PeanutSpawner_timeout"))

    var mcfg = level_cfg.get("magnet.tscn", {})
    magnet_spawner.wait_time = mcfg.get("spawn_interval", 20.0)
    magnet_spawner.one_shot  = false
    magnet_spawner.autostart = true
    magnet_spawner.connect("timeout", Callable(self, "_on_MagnetSpawner_timeout"))
    print("▶ MagnetSpawner configuré :", magnet_spawner.wait_time, "s, autostart =", magnet_spawner.autostart)


func _process(_delta: float) -> void:
    # 1) mets à jour le sommet atteint
    if player.global_position.y < best_player_y:
        best_player_y = player.global_position.y

   # 2) game over si trop bas, seuil lu au runtime dans level_cfg
    var seuil_chute: float = level_cfg.get("game_over_fall", 1200.0)
    if player.global_position.y > best_player_y + seuil_chute:
        _on_game_over()
        return

    # 3) spawn infini de plateformes vers le haut
    if player.global_position.y < highest_y + 400:
        spawn_platform(highest_y - vertical_gap)
        highest_y -= vertical_gap

    # 4) caméra suit le player (sans descendre)
    camera2d.global_position.y = min(player.global_position.y, initial_cam_y)

    # 5) height_score & palier tous les 500m
    var climbed = int((initial_player_y - player.global_position.y) / 100.0)
    if climbed > height_score:
        height_score = climbed
        label_score.text = "%d m" % height_score
        if height_score >= level * 300:
            _level_up()

    # 6) nettoyage
    var bottom = camera2d.global_position.y + get_viewport_rect().size.y * 0.5
    for b in get_tree().get_nodes_in_group("bananas"):
        if b.global_position.y > bottom: b.queue_free()
    for p in get_tree().get_nodes_in_group("peanuts"):
        if p.global_position.y > bottom: p.queue_free()
    # 6-bis) Nettoyage des magnets hors écran
    for m in get_tree().get_nodes_in_group("magnets"):
        if m.global_position.y > bottom:
            m.queue_free()
        
      # Attirer les bananes si aimant actif
    if _magnet_active:
        for b in get_tree().get_nodes_in_group("bananas"):
            var dist = b.global_position.distance_to(player.global_position)
            if dist < _magnet_radius:
                var dir = (player.global_position - b.global_position).normalized()
                b.global_position += dir * _magnet_strength * _delta
        



func _on_game_over() -> void:
    if game_over_layer.visible: return

    #get_tree().paused = true
    print("Appel GameOverLayer.show_results avec : height_score =", height_score, "banana_score =", banana_score)

    # Appelle l’animation d’affichage du score sur GameOverLayer
    $GameOverLayer.show_results(height_score, banana_score)

func _on_replay_pressed() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

func _level_up() -> void:
    level += 1
    label_level.text = "Niveau: %d" % level
    # recharge la config
    level_cfg = LevelManager.get_config_for(level)
    print("⬆️ Palier %d, nouvelle cfg :" % level, level_cfg)
    # si tu veux piloter jump/gravity depuis JSON :
    var pj = level_cfg.get("player", {})
    player.jump_force += pj.get("jump_delta", 0)
    player.gravity    += pj.get("gravity_delta", 0)

     # --- Joue le son de level up ici ---
    if level_up_sfx:
        level_up_sfx.play()

func spawn_platform(y_pos: float) -> Node2D:
    # ── 1) Lecture des configs JSON pour les deux types ──
    var p1_cfg = level_cfg.get("platform.tscn", {})
    var p2_cfg = level_cfg.get("platform2.tscn", {})

    # ── 2) Poids pour le tirage pondéré ──
    var w1 = p1_cfg.get("chance", 1.0)
    var w2 = p2_cfg.get("chance", 0.0)
    var total = w1 + w2
    var draw = randf() * total
    var use_mobile = false
    if draw >= w1:
        use_mobile = true

    # ── 3) Instanciation de la bonne scène ──
    var scene_ref: PackedScene
    if use_mobile:
        scene_ref = platform2_scene
    else:
        scene_ref = platform_scene
    var plat = scene_ref.instantiate() as Node2D
    add_child(plat)
    var type_name = ""
    if use_mobile:
        type_name = "platform2"
    else:
        type_name = "platform"
    

    # ── 4) Positionnement aléatoire X + Y fixe ──
    var vw = get_viewport_rect().size.x
    plat.position = Vector2(randi_range(100, int(vw - 100)), y_pos)

    # ── 5) Collision one-way ──
    if plat.has_node("CollisionShape2D"):
        var col = plat.get_node("CollisionShape2D") as CollisionShape2D
        col.one_way_collision = true
        col.one_way_collision_margin = 4.0

    # ── 6) Breakable & Persistent selon JSON ──
    var cfg: Dictionary
    if use_mobile:
        cfg = p2_cfg
    else:
        cfg = p1_cfg

    var is_breakable  = randf() < cfg.get("breakable", 0.0)
    var is_persistent = randf() < cfg.get("persistent", 0.0)
    
    if plat.has_method("set_breakable"):
        plat.call_deferred("set_breakable", is_breakable)
    if plat.has_method("set_persistent"):
        plat.call_deferred("set_persistent", is_persistent)

    # ── 6.1) Bounce multiplier depuis JSON ──
    var bm = cfg.get("bounce_mult", 1.0)
    
    if plat.has_method("set_bounce_mult"):
        plat.call_deferred("set_bounce_mult", bm)

    # ── 7) Mouvement static / horizontal / vertical ──
    var rnd2 = randf()
    var s    = cfg.get("static",     0.0)
    var h    = cfg.get("horizontal", 0.0)
    var v    = cfg.get("vertical",   0.0)
    
    

    return plat

func _on_BananaSpawner_timeout() -> void:
    var bcfg = level_cfg.get("banana.tscn", {})
    var max_b = bcfg.get("max_simultaneous", 2)
    # Si on n’a pas atteint le maximum…
    if get_tree().get_nodes_in_group("bananas").size() < max_b:
        var b = banana_scene.instantiate() as Area2D
        b.add_to_group("bananas")
        # positionne comme avant
        var size  = get_viewport_rect().size
        var x     = randf_range(20.0, size.x-20.0)
        var topY  = camera2d.global_position.y - size.y*0.5
        var y     = randf_range(topY - size.y*0.2, topY - 10.0)
        b.position = Vector2(x,y)
        add_child(b)
        b.connect("collected", Callable(self, "_on_banana_collected"))


func _on_banana_collected() -> void:
    banana_score += 1
    label_banana.text = "Bananes: %d" % banana_score
    banana_sfx.play()

func _on_PeanutSpawner_timeout() -> void:
    var pcfg = level_cfg.get("peanut.tscn", {})
    var max_p = pcfg.get("max_simultaneous", 1)
    # si on n’a pas déjà trop de cacahuètes à l’écran…
    if get_tree().get_nodes_in_group("peanuts").size() < max_p:
        var p = peanut_scene.instantiate() as Area2D
        p.add_to_group("peanuts")
        # positionnement comme avant…
        var size = get_viewport_rect().size
        var x    = randf_range(20.0, size.x - 20.0)
        var topY = camera2d.global_position.y - size.y * 0.5
        var y    = randf_range(topY - size.y * 0.2, topY - 10.0)
        p.position = Vector2(x, y)
        add_child(p)
        p.connect("collected", Callable(self, "_on_Peanut_collected"))

func _on_Peanut_collected(peanut_node: Node) -> void:
    var pc = level_cfg.get("peanut.tscn", {})
    peanut_sfx.play()
    peanut_node.queue_free()
    if _peanut_active:
        return
    _peanut_active = true
    _player_base_speed      = player.speed
    _player_base_jump_force = player.jump_force
    player.speed      *= pc.get("buff_multiplier", 1.0)
    player.jump_force *= pc.get("buff_multiplier", 1.0)
    await get_tree().create_timer(pc.get("buff_duration", 6.0)).timeout
    player.speed      = _player_base_speed
    player.jump_force = _player_base_jump_force
    _peanut_active    = false

func _spawn_bonus_banana_line() -> void:
    var vh: float = get_viewport_rect().size.y
    var x_pos     = player.global_position.x
    for i in range(50):
        var b = banana_scene.instantiate() as Area2D
        b.add_to_group("bananas")
        b.position = Vector2(x_pos,
            camera2d.global_position.y - vh * 0.5 - i * (vh / 10))
        add_child(b)
        b.connect("collected", Callable(self, "_on_banana_collected"))
        
        
func _on_MagnetSpawner_timeout() -> void:
    var mcfg = level_cfg.get("magnet.tscn", {})
    print("🧲 _on_MagnetSpawner_timeout — chance:", mcfg.get("chance", 0.0))
    if randf() < mcfg.get("chance", 0.0) \
    and get_tree().get_nodes_in_group("magnets").size() < mcfg.get("max_simultaneous", 1):
        var m = preload("res://scenes/magnet.tscn").instantiate() as Area2D
        m.add_to_group("magnets")
        # positionne juste au‐dessus de l’écran
        var size = get_viewport_rect().size
        var x = randf_range(20.0, size.x - 20.0)
        var y = camera2d.global_position.y - size.y * 0.6
        m.position = Vector2(x, y)
        add_child(m)
        m.connect("collected", Callable(self, "_on_Magnet_collected"))
    else:
        print("   → pas de magnet ce tour-ci")

func _on_Magnet_collected(magnet_node: Node) -> void:
    var mcfg = level_cfg.get("magnet.tscn", {})
    print("🧲 _on_Magnet_collected — duration:", mcfg.get("duration"), 
          " radius:", mcfg.get("radius"), " strength:", mcfg.get("strength"))
    magnet_sfx.play()
    magnet_node.queue_free()
    _magnet_active   = true
    _magnet_radius   = mcfg.get("radius", 0.0)
    _magnet_strength = mcfg.get("strength", 0.0)
    # on attend la durée définie dans le JSON
    await get_tree().create_timer(mcfg.get("duration", 5.0)).timeout
    _magnet_active = false
    print("🧲 Magnet désactivé")




func _create_ground_and_player() -> void:
    var vw: float = get_viewport_rect().size.x
    var vh: float = get_viewport_rect().size.y
    var ground = ground_scene.instantiate()
    add_child(ground)
    var shape = ground.get_node("CollisionShape2D").shape as RectangleShape2D
    var gh    = shape.extents.y * 2.0
    ground.position = Vector2(vw * 0.5, vh - gh * 0.5)
    ground_y        = ground.position.y
    player.global_position = Vector2(
        ground.position.x,
        ground.position.y - shape.extents.y - 1
    )
    initial_cam_y = vh * 0.6
    camera2d.global_position.y = initial_cam_y

func _spawn_initial_platforms() -> void:
    var start_y = ground_y - vertical_gap
    for i in range(initial_platforms):
        spawn_platform(start_y - i * vertical_gap)
    highest_y = start_y - (initial_platforms - 1) * vertical_gap

func setup_borders() -> void:
    var size: Vector2 = get_viewport_rect().size
    var t: float = 10.0
    for x in [0, size.x]:
        var wall = StaticBody2D.new()
        var r    = RectangleShape2D.new()
        r.extents = Vector2(t, size.y * 0.5)
        var col  = CollisionShape2D.new()
        col.shape = r
        wall.position = Vector2(x, size.y * 0.5)
        wall.add_child(col)
        add_child(wall)
    var ui = CanvasLayer.new()
    add_child(ui)
    for x in [0, size.x]:
        var bar = ColorRect.new()
        bar.color    = Color(1,1,1,1)
        bar.position = Vector2(x - t * 0.5, 0)
        bar.size     = Vector2(t, size.y)
        ui.add_child(bar)
