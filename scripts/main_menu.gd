extends CanvasLayer

@export var game_scene_path        : String = "res://scenes/Game.tscn"
@export var leaderboard_scene     : String = ""  # si plugin GameCenter
@export var settings_scene_path   : String = ""  # optionnel

func _ready():
    $VBoxContainer/PlayButton.connect("pressed", Callable(self, "_on_Play_pressed"))
    $VBoxContainer/LeaderboardButton.connect("pressed", Callable(self, "_on_Leaderboard_pressed"))
    $VBoxContainer/SettingsButton.connect("pressed", Callable(self, "_on_Settings_pressed"))
    $VBoxContainer/QuitButton.connect("pressed", Callable(self, "_on_Quit_pressed"))

func _on_Play_pressed():
    get_tree().change_scene_to_file(game_scene_path)

##func _on_Leaderboard_pressed():
##    if Engine.has_singleton("GameCenter"):
##       GameCenter.show_leaderboard()  # selon ton plugin
##    else:
##        print("Plugin GameCenter non configuré")

func _on_Settings_pressed():
    if settings_scene_path != "":
        get_tree().change_scene(settings_scene_path)

func _on_Quit_pressed():
    get_tree().quit()
