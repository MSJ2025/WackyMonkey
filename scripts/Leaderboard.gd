extends Control

@onready var container = $Panel/VBoxContainer
@onready var btn_close = $Panel/Button

# Liste locale des scores (dictionnaires {username, score})
var local_scores : Array = []

func _ready():
    btn_close.connect("pressed", Callable(self, "_on_close_pressed"))
    hide()  # cacher au départ
    load_scores_local()

func show_leaderboard():
    show()
    display_leaderboard(local_scores)

func _on_close_pressed():
    hide()

# Charger les scores depuis un fichier local
func load_scores_local():
    var config = ConfigFile.new()
    var err = config.load("user://leaderboard.cfg")
    local_scores.clear()
    if err == OK:
        for i in range(config.get_section_keys("scores").size()):
            var key = "score_%d" % i
            if config.has_section_key("scores", key + "_username") and config.has_section_key("scores", key + "_value"):
                var username = config.get_value("scores", key + "_username", "Anonyme")
                var score = int(config.get_value("scores", key + "_value", 0))
                local_scores.append({"username": username, "score": score})
        # Trie décroissant sur score
        local_scores.sort_custom(func(a,b): return int(b["score"]) - int(a["score"]))
    else:
        print("Pas de fichier de scores local trouvé")

# Sauvegarder les scores dans un fichier local
func save_scores_local():
    var config = ConfigFile.new()
    config.clear()
    for i in range(local_scores.size()):
        var key = "score_%d" % i
        config.set_value("scores", key + "_username", local_scores[i]["username"])
        config.set_value("scores", key + "_value", local_scores[i]["score"])
    var err = config.save("user://leaderboard.cfg")
    if err != OK:
        print("Erreur lors de la sauvegarde des scores")

# Ajouter un score localement (avec tri et limite à 10)
func add_score(username: String, score: int):
    local_scores.append({"username": username, "score": score})
    # Trie décroissant
    local_scores.sort_custom(func(a,b): return int(b["score"]) - int(a["score"]))
    # Limite à 10 scores
    if local_scores.size() > 10:
        local_scores = local_scores.slice(0, 10)
    save_scores_local()

func display_leaderboard(scores: Array) -> void:
    container.clear()
    for i in range(scores.size()):
        var entry = scores[i]
        var label = Label.new()
        label.text = "%d. %s : %d" % [i + 1, entry["username"], entry["score"]]
        container.add_child(label)
