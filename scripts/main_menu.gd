extends CanvasLayer

@export var game_scene_path        : String = "res://scenes/Game.tscn"
@export var leaderboard_scene      : String = "res://scenes/Leaderboard.tscn"
@export var settings_scene_path    : String = "res://scenes/settings.tscn"  # optionnel

@onready var pseudo_lineedit = $VBoxContainer/PseudoLineEdit
@onready var label_pseudo = $LabelPseudo

var Firebase = Engine.get_singleton("Firebase")

func _ready():
    print("DEBUG: _ready() called")
    
    var saved_pseudo = ScoreManager.load_pseudo()
    print("DEBUG: Pseudo chargé au menu:", saved_pseudo)
    
    if saved_pseudo == "" or saved_pseudo == null:
        pseudo_lineedit.visible = true
        label_pseudo.visible = false
        pseudo_lineedit.text = ""
    else:
        pseudo_lineedit.visible = false
        label_pseudo.visible = true
        label_pseudo.text = " %s" % saved_pseudo
        pseudo_lineedit.text = saved_pseudo

    pseudo_lineedit.text_changed.connect(_on_PseudoLineEdit_text_changed)
    $VBoxContainer/PlayButton.pressed.connect(_on_Play_pressed)
    $VBoxContainer/LeaderboardButton.pressed.connect(_on_Leaderboard_pressed)
    $VBoxContainer/SettingsButton.pressed.connect(_on_Settings_pressed)
    $VBoxContainer/QuitButton.pressed.connect(_on_Quit_pressed)

    # Lancement de la vérification de mise à jour
    VersionManager.check_for_update()


func _on_Play_pressed():
    var pseudo = pseudo_lineedit.text.strip_edges()
    ScoreManager.save_pseudo(pseudo)
    if Engine.has_singleton("Firebase"):
        Firebase.Analytics.log_event("play_pressed")
    get_tree().change_scene_to_file(game_scene_path)

func _on_Leaderboard_pressed():
    var pseudo = pseudo_lineedit.text.strip_edges()
    if pseudo == "":
        show_message("Merci de saisir un pseudo !")
        return
    ScoreManager.save_pseudo(pseudo)
    if Engine.has_singleton("Firebase"):
        Firebase.Analytics.log_event("leaderboard_opened")
    get_tree().change_scene_to_file(leaderboard_scene)

func _on_Settings_pressed():
    if settings_scene_path != "":
        if Engine.has_singleton("Firebase"):
            Firebase.Analytics.log_event("settings_opened")
        get_tree().change_scene_to_file(settings_scene_path)

func _on_Quit_pressed():
    if Engine.has_singleton("Firebase"):
        Firebase.Analytics.log_event("quit_pressed")
    get_tree().quit()

func show_message(msg):
    print(msg)

func _on_PseudoLineEdit_text_changed(new_text):
    var pseudo = new_text.strip_edges()
    var device_id = ScoreManager.load_device_id()
    if pseudo == "":
        $VBoxContainer/PlayButton.disabled = true
        $VBoxContainer/LeaderboardButton.disabled = true
        show_message("Merci de saisir un pseudo !")
        return
    FirestoreManager.check_pseudo_unique(pseudo, device_id, func(is_unique):
        if is_unique:
            $VBoxContainer/PlayButton.disabled = false
            $VBoxContainer/LeaderboardButton.disabled = false
            show_message("")
            ScoreManager.save_pseudo(pseudo)
        else:
            $VBoxContainer/PlayButton.disabled = true
            $VBoxContainer/LeaderboardButton.disabled = true
            show_message("Pseudo déjà pris, choisis-en un autre !")
    )
