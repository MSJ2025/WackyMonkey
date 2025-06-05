extends Node

var message: String = ""

func _load_local() -> String:
    var config = ConfigFile.new()
    if config.load("user://admin_message.cfg") == OK:
        return str(config.get_value("admin", "message", ""))
    return ""

func _save_local():
    var config = ConfigFile.new()
    config.set_value("admin", "message", message)
    config.save("user://admin_message.cfg")

func load_message() -> String:
    message = _load_local()
    print("Message charg\u00e9 :", message)
    return message

func fetch_message(callback):
    FirestoreManager.fetch_admin_message(func(msg):
        if msg == null or msg == "":
            message = _load_local()
        else:
            message = msg
            _save_local()
        if callback:
            callback.call(message)
    )

func save_message(new_message: String, callback = null) -> void:
    message = new_message
    FirestoreManager.save_admin_message(message, func(success):
        if success:
            _save_local()
        if callback:
            callback.call(success)
    )
