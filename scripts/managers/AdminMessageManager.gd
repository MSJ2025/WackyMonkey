extends Node

var message: String = ""

func load_message() -> String:
    var config = ConfigFile.new()
    if config.load("user://admin_message.cfg") == OK:
        message = str(config.get_value("admin", "message", ""))
    return message

func save_message(new_message: String) -> void:
    message = new_message
    var config = ConfigFile.new()
    config.set_value("admin", "message", message)
    config.save("user://admin_message.cfg")
