extends CanvasLayer

@onready var message_edit = $VBoxContainer/MessageEdit
@onready var btn_save = $VBoxContainer/BtnSave
@onready var btn_back = $VBoxContainer/BtnBack

func _ready():
    message_edit.text = AdminMessageManager.load_message()
    btn_save.pressed.connect(_on_save_pressed)
    btn_back.pressed.connect(_on_back_pressed)

func _on_save_pressed():
    AdminMessageManager.save_message(message_edit.text)
    print("Message enregistr\u00e9")

func _on_back_pressed():
    get_tree().change_scene_to_file("res://scenes/settings.tscn")
