# res://scripts/LevelManager.gd
extends Node

@export var levels_config_path: String = "res://data/levels.json"
var config: Dictionary = {}

func _ready() -> void:
    # 1) Vérifie que le fichier existe
    if not FileAccess.file_exists(levels_config_path):
        push_error("LevelManager : impossible d’ouvrir %s" % levels_config_path)
        return

    # 2) Lit tout le JSON
    var text: String = FileAccess.get_file_as_string(levels_config_path)

    # 3) Parse via une instance de JSON
    var parser := JSON.new()
    var err_code := parser.parse(text)
    if err_code != OK:
        push_error("LevelManager : JSON invalide – %s" % parser.get_error_message())
        return

    # 4) Récupère le dictionnaire complet
    config = parser.get_data() as Dictionary

# Retourne {} si pas de config pour ce niveau
func get_config_for(level: int) -> Dictionary:
    var key := str(level)
    if config.has(key):
        return config[key] as Dictionary
    return {}
