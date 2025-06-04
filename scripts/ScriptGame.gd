extends Node2D

# — PackedScenes & JSON —
@export var ground_scene       : PackedScene
@export var platform_scene     : PackedScene
@export var platform2_scene    : PackedScene
@export var banana_scene       : PackedScene
@export var peanut_scene       : PackedScene
@export var initial_platforms  : int    = 10
@export var vertical_gap       : float  = 200.0
@export var score_line_scene: PackedScene
 

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

# — Buffs & bonus —
var _peanut_active          : bool  = false
var _player_base_speed      : float = 0.0
var _player_base_jump_force : float = 0.0
var _magnet_active : bool = false
var _magnet_radius : float = 0.0
var _magnet_strength : float = 0.0


const PIXELS_PAR_METRE = 100.0  # Par exemple : 100 pixels = 1 mètre
var PALIER_METRES = 100  # ou 300 selon besoin
var prochain_palier := 1
var palier_y := 0.0  # Premier palier à atteindre après le début (niveau 2)

# — Nodes —
@onready var camera2d        : Camera2D          = $Camera2D
@onready var player          : CharacterBody2D   = $Player
@onready var label_score     : Label             = $CanvasLayer/LabelScore
@onready var label_banana    : Label             = $CanvasLayer/BananaScore
@onready var label_level     : Label             = $CanvasLayer/Level
@onready var banana_spawner  : Timer             = $BananaSpawner
@onready var peanut_spawner  : Timer             = $PeanutSpawner
@onready var magnet_spawner  : Timer             = $MagnetSpawner
@onready var game_over_layer : CanvasLayer       = $GameOverLayer
@onready var banana_sfx      : AudioStreamPlayer = $BananaPlayer
@onready var peanut_sfx      : AudioStreamPlayer = $PeanutPlayer
@onready var magnet_sfx      : AudioStreamPlayer = $MagnetPlayer
@onready var level_up_sfx    : AudioStreamPlayer = $LevelUpPlayer
@onready var burp_sfx      : AudioStreamPlayer = $BurpPlayer
@onready var level_line = $LevelLine
@onready var label_level_line = $LevelLine/LabelLevelLine


var _pending_action: String = ""

func _ready() -> void:
    print("LevelLine ?", level_line)
    print("LabelLevelLine ?", label_level_line)
    # — 1) Charge la config JSON pour ce niveau
    level_cfg = LevelManager.get_config_for(level)
    print("▶️ ScriptGame, niveau %d, cfg :" % level, level_cfg)
    print_debug("► Level_cfg chargé pour le niveau %d : %s" % [level, level_cfg])
    FirestoreManager.fetch_top_scores(func(scores):
        afficher_leaderboard(scores)
)

    # — 2) Setup Game Over
    game_over_layer.visible = false
    var btn = game_over_layer.get_node_or_null("ColorRect/VBoxContainer/ReplayButton") as Button
    if btn:
        btn.connect("pressed", Callable(self, "_on_replay_pressed"))

    # — 3) Création du sol, player, plateformes initiales & caméra
    _create_ground_and_player()
    _spawn_initial_platforms()

    # — 4) Repères de hauteur
    initial_player_y = player.global_position.y
    best_player_y    = initial_player_y
    prochain_palier = 1
    _update_palier_y()
    _affiche_palier()

    # — 5) Scores & UI
    height_score  = 0
    banana_score  = 0
    label_score.text  = "%d m"        % height_score
    label_banana.text = "Bananes: %d" % banana_score
    label_level.text  = "Niveau: %d"  % level

    # — 6) Murs et bordures
    setup_borders()

    # — 7) Configure les spawners
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

    # — 8) Chargement pseudo utilisateur
    var saved_pseudo = ScoreManager.load_pseudo()
    if saved_pseudo != "":
        var pseudo = ScoreManager.load_pseudo()
        
    

func _reset_level_line():
    # Place la barre au premier palier à venir (Niveau 2)
    var next_palier_y = initial_player_y - PALIER_METRES
    _affiche_palier()

func _on_pseudo_text_changed(new_text):
    ScoreManager.save_pseudo(new_text)


func _process(delta: float) -> void:
# PALIER : gestion barre de niveau
    var current_y = player.global_position.y

    # Calcul du bas de l'écran (coordonnée monde)
    var bottom_screen_y = camera2d.global_position.y + get_viewport_rect().size.y * 0.5

    # Tant que la barre du palier est encore visible, elle reste affichée
    if palier_y > bottom_screen_y:
        _cache_palier()
        # La barre actuelle a quitté l'écran : prépare la suivante
        prochain_palier += 1
        _update_palier_y()
        _affiche_palier()
        
        
    # Record de la hauteur maximale atteinte
    if player.global_position.y < best_player_y:
        best_player_y = player.global_position.y
        
    # 2) game over si trop bas, seuil lu au runtime dans level_cfg
    var seuil_chute: float = level_cfg.get("game_over_fall", 1200.0)
    if player.global_position.y > best_player_y + seuil_chute:
        _on_game_over()
        return

    # 3) spawn infini de plateformes vers le haut
    if player.global_position.y < highest_y + 900:
        spawn_platform(highest_y - vertical_gap)
        highest_y -= vertical_gap

    # 4) caméra suit le player (sans descendre)
    camera2d.global_position.y = min(player.global_position.y, initial_cam_y)

    # 5) height_score & palier tous les 500m
    var climbed = int((initial_player_y - player.global_position.y) / PIXELS_PAR_METRE)
    if climbed > height_score:
        height_score = climbed
        label_score.text = "%d m" % height_score
        if height_score >= level * PALIER_METRES:
            _level_up()

    # 6) nettoyage
    var bottom = camera2d.global_position.y + get_viewport_rect().size.y * 0.5
    for b in get_tree().get_nodes_in_group("bananas"):
        if b.global_position.y > bottom: b.queue_free()
    for p in get_tree().get_nodes_in_group("peanuts"):
        if p.global_position.y > bottom: p.queue_free()
    for m in get_tree().get_nodes_in_group("magnets"):
        if m.global_position.y > bottom: m.queue_free()

    # Aimant (magnet)
    if _magnet_active:
        for b in get_tree().get_nodes_in_group("bananas"):
            var dist = b.global_position.distance_to(player.global_position)
            if dist < _magnet_radius:
                var dir = (player.global_position - b.global_position).normalized()
                b.global_position += dir * _magnet_strength * delta
                

    
func _update_palier_y():
    palier_y = initial_player_y - (PIXELS_PAR_METRE * PALIER_METRES * prochain_palier)

func _affiche_palier():
    level_line.visible = true
    label_level_line.visible = true
    level_line.global_position.y = palier_y
    label_level_line.text = "NIVEAU %d" % (prochain_palier + 1)

func _cache_palier():
    level_line.visible = false
    label_level_line.visible = false
    
    
func _on_game_over() -> void:
    if game_over_layer.visible: return

    print("Appel GameOverLayer.show_results avec : height_score =", height_score, "banana_score =", banana_score)

    var score_final = int(height_score * 0.5 + banana_score * 5)
    var pseudo = ScoreManager.load_pseudo()
    if pseudo == "":
        pseudo = "Anonyme"

    var device_id = OS.get_unique_id() # ou ta méthode de récupération device id

    # Enregistrement en local
    ScoreManager.add_score(pseudo, score_final)

    # Envoi Firestore EN LIGNE
    FirestoreManager.submit_score_if_best(
        pseudo,          # 1
        score_final,     # 2
        device_id,       # 3
        height_score,    # 4 (la meilleure hauteur atteinte)
        func(result):    # 5
            print("Score soumis :", result)
    )

    game_over_layer.show_results(height_score, banana_score)

func _on_replay_pressed() -> void:
    _save_and_go_to_scene("res://scenes/Game.tscn")  # <-- ICI

func _on_menu_pressed() -> void:
    _save_and_go_to_scene("res://scenes/MainMenu.tscn")  # <-- ICI
    
func _save_and_go_to_scene(scene_path: String) -> void:
    get_tree().change_scene_to_file(scene_path)

func show_message(msg: String) -> void:
    print(msg)
    # Ou mets à jour un Label prévu à cet effet si tu veux une UI


func _spawn_initial_platforms():
    var start_y = ground_y - vertical_gap
    for i in range(initial_platforms):
        spawn_platform(start_y - i * vertical_gap)
    highest_y = start_y - (initial_platforms - 1) * vertical_gap

func setup_borders():
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

func _level_up() -> void:
    level += 1
    label_level.text = "Niveau: %d" % level
    level_cfg = LevelManager.get_config_for(level)
    print("⬆️ Palier %d, nouvelle cfg :" % level, level_cfg)
    # Positionne la barre du niveau SUIVANT
    var next_palier_y = initial_player_y - (level * PALIER_METRES)
    _affiche_palier()
    # Améliorations de progression
    var pj = level_cfg.get("player", {})
    player.jump_force += pj.get("jump_delta", 0)
    player.gravity    += pj.get("gravity_delta", 0)
    if level_up_sfx:
        level_up_sfx.play()
        

func spawn_platform(y_pos: float) -> Node2D:
    var p1_cfg = level_cfg.get("platform.tscn", {})
    var p2_cfg = level_cfg.get("platform2.tscn", {})
    var w1 = p1_cfg.get("chance", 1.0)
    var w2 = p2_cfg.get("chance", 0.0)
    var total = w1 + w2
    var draw = randf() * total
    var use_mobile = false
    if draw >= w1:
        use_mobile = true
    var scene_ref: PackedScene = platform2_scene if use_mobile else platform_scene
    var plat = scene_ref.instantiate() as Node2D
    add_child(plat)
    var cfg: Dictionary = p2_cfg if use_mobile else p1_cfg
    var vw = get_viewport_rect().size.x
    plat.position = Vector2(randi_range(100, int(vw - 100)), y_pos)
    if plat.has_node("CollisionShape2D"):
        var col = plat.get_node("CollisionShape2D") as CollisionShape2D
        col.one_way_collision = true
        col.one_way_collision_margin = 4.0
    var is_breakable  = randf() < cfg.get("breakable", 0.0)
    var is_persistent = randf() < cfg.get("persistent", 0.0)
    if plat.has_method("set_breakable"):
        plat.call_deferred("set_breakable", is_breakable)
    if plat.has_method("set_persistent"):
        plat.call_deferred("set_persistent", is_persistent)
    var bm = cfg.get("bounce_mult", 1.0)
    if plat.has_method("set_bounce_mult"):
        plat.call_deferred("set_bounce_mult", bm)
        
    # -----------------------
    # *** AJOUT ICI ***
    # Gestion du mode de mouvement (static, horizontal, vertical)
    var prob_static = cfg.get("static", 1.0)
    var prob_horizontal = cfg.get("horizontal", 0.0)
    var prob_vertical = cfg.get("vertical", 0.0)
    var move_draw = randf()
    var mode = "static"
    if move_draw < prob_static:
        mode = "static"
    elif move_draw < prob_static + prob_horizontal:
        mode = "horizontal"
    else:
        mode = "vertical"
    var move_range = cfg.get("move_range", 200.0)
    var move_time = cfg.get("move_time", 4.0)
    if mode == "horizontal" and plat.has_method("_start_moving_horizontal"):
        plat.call_deferred("_start_moving_horizontal", move_range, move_time)
    elif mode == "vertical" and plat.has_method("_start_moving_vertical"):
        plat.call_deferred("_start_moving_vertical", move_range, move_time)
    # -----------------------

    return plat

func _on_BananaSpawner_timeout() -> void:
    var bcfg = level_cfg.get("banana.tscn", {})
    var max_b = bcfg.get("max_simultaneous", 2)
    if get_tree().get_nodes_in_group("bananas").size() < max_b:
        var b = banana_scene.instantiate() as StaticBody2D
        b.add_to_group("bananas")
        var size  = get_viewport_rect().size
        var x     = randf_range(20.0, size.x-20.0)
        var topY  = camera2d.global_position.y - size.y*0.5
        var y     = randf_range(topY - size.y*0.2, topY - 10.0)
        b.position = Vector2(x,y)
        add_child(b)
        b.connect("collected", Callable(self, "_on_banana_collected"))

func _on_banana_collected() -> void:
    print("Banana collected, play sound")
    banana_score += 1
    label_banana.text = "Bananes: %d" % banana_score
    print("banana_sfx is: ", banana_sfx)
    if banana_sfx:
        print("banana_sfx exists, playing sound")
        if banana_sfx.playing:
            print("banana_sfx is already playing, stopping first")
            banana_sfx.stop()
        banana_sfx.play()
    else:
        print("banana_sfx is null or not assigned")
    
    if banana_score % 10 == 0:
        print("Playing burp sound")
        burp_sfx.play()
        
        # Option 2 (plus propre) : attendre la fin de banana_sfx avant de jouer burp_sfx
        # Connecte le signal "finished" si tu veux cette option :
        # banana_sfx.finished.connect(_on_banana_sfx_finished)

func _on_PeanutSpawner_timeout() -> void:
    var pcfg = level_cfg.get("peanut.tscn", {})
    var max_p = pcfg.get("max_simultaneous", 1)
    if get_tree().get_nodes_in_group("peanuts").size() < max_p:
        var p = peanut_scene.instantiate() as StaticBody2D
        p.add_to_group("peanuts")
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
        var b = banana_scene.instantiate() as StaticBody2D
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
        var m = preload("res://scenes/magnet.tscn").instantiate() as StaticBody2D
        m.add_to_group("magnets")
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

    # PLACEMENT DU PLAYER (INDISPENSABLE !)
    player.global_position = Vector2(
        ground.position.x,
        ground.position.y - shape.extents.y - 1
    )
    initial_cam_y = vh * 0.6
    camera2d.global_position.y = initial_cam_y
    
func afficher_leaderboard(scores: Array):
    for entry in scores:
        var line = score_line_scene.instantiate()
        var score_y = initial_player_y - (entry.best_height * PIXELS_PAR_METRE)
        line.position = Vector2(0, score_y)
        add_child(line) # <-- D'abord on l'ajoute à la scène !
        line.set_score(entry.pseudo, entry.best_height)
        print("Ajout ligne pour %s à %d m (y=%d)" % [entry.pseudo, entry.best_height, score_y])
