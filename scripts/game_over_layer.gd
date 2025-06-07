extends CanvasLayer

@onready var label_meters     = $VBoxContainer/LabelMeters
@onready var label_bananas    = $VBoxContainer/LabelBananas
@onready var label_score      = $VBoxContainer/LabelScore
@onready var label_best_score = $VBoxContainer/LabelBestScore
@onready var replay_button    = $VBoxContainer/HBoxContainer/ReplayButton
@onready var menu_button      = $VBoxContainer/HBoxContainer/MenuButton

var final_meters   : int = 0
var final_bananas  : int = 0
var final_score    : int = 0
var displayed_score: int = 0
var anim_speed     : int = 600   # points par seconde

func show_results(height, bananas):
    # Recharge le tableau des scores pour disposer de la dernière version
    ScoreManager.load()
    final_meters = int(height)
    final_bananas = int(bananas)
    final_score = final_meters * 0.5 + final_bananas * 5
    label_meters.text  = "Hauteur : %d m (x0,5)" % final_meters
    label_bananas.text = "Bananes : %d (×5)" % final_bananas
    displayed_score = 0
    label_score.text = "Score : 0"
    visible = true
    set_process(true)
    _save_score()

func _process(delta):
    if displayed_score < final_score:
        displayed_score += int(anim_speed * delta)
        if displayed_score > final_score:
            displayed_score = final_score
        label_score.text = "Score : %d" % displayed_score
    else:
        set_process(false)
        # Afficher le meilleur score enregistré localement
        var best = ScoreManager.get_best_score()
        label_best_score.text = "🏆 Record : %d" % best

        # ACTIVER LES BOUTONS ici si besoin
        replay_button.disabled = false
        menu_button.disabled = false

func _save_score():
    var pseudo = ScoreManager.load_pseudo()
    var device_id = ScoreManager.load_device_id()
    # Enregistre toujours en local
    ScoreManager.add_score(pseudo, final_score)
    print("LEADERBOARD après ajout : ", ScoreManager.get_top_scores())
    # ENREGISTRE SUR FIRESTORE uniquement si pseudo OK et score meilleur
    FirestoreManager.submit_score_if_best(
        pseudo,
        final_score,
        device_id,
        final_meters,  # <-- On ajoute la meilleure hauteur ici
        func(sucess):
            if not sucess:
                show_message("Score non envoyé (pseudo pris ou score inférieur au précédent)")
    )

func _on_replay_pressed():
    get_tree().reload_current_scene()

func _on_menu_pressed():
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
    
func show_message(msg: String):
    print(msg) # À remplacer par un affichage graphique si tu veux
