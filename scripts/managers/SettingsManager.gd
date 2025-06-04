extends Node

var music_volume := 1.0
var sfx_volume := 1.0
var vibration := true

func _ready():
    load_settings()

func set_music_volume(v):
    music_volume = v
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(v))
    save_settings()

func set_sfx_volume(v):
    sfx_volume = v
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(v))
    save_settings()

func set_vibration(val):
    vibration = val
    save_settings()

func get_music_volume():
    return music_volume

func get_sfx_volume():
    return sfx_volume

func get_vibration():
    return vibration

func save_settings():
    var config = ConfigFile.new()
    config.set_value("audio", "music_volume", music_volume)
    config.set_value("audio", "sfx_volume", sfx_volume)
    config.set_value("game", "vibration", vibration)
    config.save("user://settings.cfg")

func load_settings():
    var config = ConfigFile.new()
    if config.load("user://settings.cfg") == OK:
        music_volume = float(config.get_value("audio", "music_volume", 1.0))
        sfx_volume = float(config.get_value("audio", "sfx_volume", 1.0))
        vibration = bool(config.get_value("game", "vibration", true))
