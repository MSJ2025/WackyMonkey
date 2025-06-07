# scripts/ScoreManager.gd
extends Node

var leaderboard : Array = []

func _ready() -> void:
    load()

func load_pseudo() -> String:
    var config = ConfigFile.new()
    var err = config.load("user://user_settings.cfg")
    if err == OK:
        return config.get_value("user", "pseudo", "")
    return ""

func add_score(pseudo: String, score: int) -> void:
    leaderboard.append({"pseudo": pseudo, "score": int(score)})
    # Toujours trier en mémoire, du plus haut au plus bas
    leaderboard.sort_custom(func(a, b): return int(b["score"]) - int(a["score"]))
    if leaderboard.size() > 10:
        leaderboard = leaderboard.slice(0, 10)
    save()

func save():
    var config = ConfigFile.new()
    # Toujours sauver les scores du plus haut au plus bas
    leaderboard.sort_custom(func(a, b): return int(b["score"]) - int(a["score"]))
    for i in range(leaderboard.size()):
        var key = "score_%d" % i
        config.set_value("scores", key + "_username", leaderboard[i]["pseudo"])
        config.set_value("scores", key + "_value", int(leaderboard[i]["score"]))
    config.save("user://leaderboard.cfg")

func load():
    leaderboard.clear()
    var config = ConfigFile.new()
    var err = config.load("user://leaderboard.cfg")
    if err == OK:
        for i in range(10):
            var key = "score_%d" % i
            var pseudo = config.get_value("scores", key + "_username", null)
            var score = config.get_value("scores", key + "_value", null)
            if pseudo != null and score != null:
                leaderboard.append({"pseudo": pseudo, "score": int(score)})
    # Toujours trier après chargement
    leaderboard.sort_custom(func(a, b): return int(b["score"]) - int(a["score"]))

func get_top_scores() -> Array:
    # Renvoie une copie triée à l’affichage
    var copy = leaderboard.duplicate()
    copy.sort_custom(func(a, b): return int(b["score"]) - int(a["score"]))
    return copy
    
func save_pseudo(pseudo: String) -> void:
    var config = ConfigFile.new()
    config.set_value("user", "pseudo", pseudo)
    config.save("user://user_settings.cfg")
    
var device_id : String = ""

func load_device_id() -> String:
    var config = ConfigFile.new()
    var err = config.load("user://device.cfg")
    if err == OK:
        return config.get_value("device", "id", "")
    # Génère si inexistant
    var rng = RandomNumberGenerator.new()
    var uuid = "%08x%08x%08x%08x" % [
        rng.randi(), rng.randi(), rng.randi(), rng.randi()
    ]
    config.set_value("device", "id", uuid)
    config.save("user://device.cfg")
    return uuid
    
func reset_local_scores():
    var config = ConfigFile.new()
    config.set_value("score", "local_score", 0)
    config.save("user://user_data.cfg")

func reset() -> void:
    leaderboard.clear()
    save()
    reset_local_scores()
    
func get_best_score() -> int:
    if leaderboard.is_empty():
        return 0
    leaderboard.sort_custom(func(a, b): return int(b["score"]) - int(a["score"]))
    return leaderboard[0]["score"]
    
func get_best_height():
    # Ex : retourne le best_height en local, à adapter selon comment tu le stockes
    return ProjectSettings.get_setting("user/best_height", 0)
