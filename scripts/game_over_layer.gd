extends CanvasLayer

@onready var label_meters     = $VBoxContainer/LabelMeters
@onready var label_bananas    = $VBoxContainer/LabelBananas
@onready var label_score      = $VBoxContainer/LabelScore
@onready var label_best_score = $VBoxContainer/LabelBestScore
@onready var replay_button    = $VBoxContainer/HBoxContainer/ReplayButton
@onready var menu_button      = $VBoxContainer/HBoxContainer/MenuButton

# Variables d’animation
var final_meters   : int = 0
var final_bananas  : int = 0
var final_score    : int = 0
var displayed_score: int = 0
var anim_speed     : int = 600   # points par seconde

var best_score     : int = 0

func _ready():
    print("=> GameOverLayer READY sur self:", self)
    visible = false
    replay_button.pressed.connect(_on_replay_pressed)
    menu_button.pressed.connect(_on_menu_pressed)

func show_results(height, bananas):
    print("== NOUVEL APPEL show_results avec :", height, bananas, "sur self:", self)
    print("Appel show_results avec : height =", height, ", bananas =", bananas)
    final_meters = int(height)
    final_bananas = int(bananas)
    final_score = final_meters * 0.5 + final_bananas * 5
    print("Score calculé :", final_score, "(", final_meters, "+", final_bananas, "* 50)")
    print("Instance unique GameOverLayer ?", self)
    
    label_meters.text  = "Hauteur : %d m (x0,5)" % final_meters
    label_bananas.text = "Bananes : %d (×5)" % final_bananas

    displayed_score = 0
    label_score.text = "Score : 0"

    # Gestion high score sera faite APRÈS l’animation

    visible = true
    set_process(true)

func _process(delta):
    print("== _process sur self:", self, "displayed_score:", displayed_score, "final_score:", final_score)
    print("Instance unique _process ?", self)
    print("Dans _process. displayed_score=", displayed_score, "final_score=", final_score)
    if displayed_score < final_score:
        displayed_score += int(anim_speed * delta)
        if displayed_score > final_score:
            displayed_score = final_score
        label_score.text = "Score : %d" % displayed_score
    else:
        set_process(false)
        # Quand l’animation du score est terminée, affiche/actualise le high score
        var best = load_best_score()
        if final_score > best:
            save_best_score(final_score)
            label_best_score.text = "🎉 Nouveau record ! %d" % final_score
        else:
            label_best_score.text = "Meilleur score : %d" % best

# --- High Score : sauvegarde/lecture locale ---
func save_best_score(score):
    var config = ConfigFile.new()
    config.set_value("score", "best", score)
    config.save("user://high_score.cfg")

func load_best_score():
    var config = ConfigFile.new()
    var err = config.load("user://high_score.cfg")
    if err == OK:
        return config.get_value("score", "best", 0)
    return 0

# --- Callbacks boutons ---
func _on_replay_pressed():
    get_tree().reload_current_scene()

func _on_menu_pressed():
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
