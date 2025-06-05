extends CanvasLayer

@onready var message_edit = $VBoxContainer/MessageEdit
@onready var btn_save = $VBoxContainer/BtnSave
@onready var btn_clear = $VBoxContainer/BtnClear
@onready var btn_back = $VBoxContainer/BtnBack

func _ready():
    message_edit.text = AdminMessageManager.load_message()
    AdminMessageManager.fetch_message(func(msg):
        message_edit.text = msg
    )
    btn_save.pressed.connect(_on_save_pressed)
    btn_clear.pressed.connect(_on_clear_pressed)
    btn_back.pressed.connect(_on_back_pressed)

func _on_save_pressed():
    AdminMessageManager.save_message(message_edit.text, func(success):
        if success:
            print("Message enregistr\u00e9")
        else:
            print("Erreur lors de l'enregistrement du message")
    )

func _on_clear_pressed():
    AdminMessageManager.clear_message(func(success):
        if success:
            message_edit.text = ""
            print("Message effac\u00e9")
        else:
            print("Erreur lors de la suppression du message")
    )

func _on_back_pressed():
    get_tree().change_scene_to_file("res://scenes/settings.tscn")
