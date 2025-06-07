extends CanvasLayer


@onready var slider_music   = $VBoxContainer/HBoxMusic/HSlider
@onready var slider_sfx     = $VBoxContainer/HBoxSFX/HSlider
@onready var option_lang    = $VBoxContainer/HBoxLangue/OptionButton
@onready var check_vibro    = $VBoxContainer/HBoxVibro/CheckButton
@onready var label_pseudo   = $VBoxContainer/HBoxPseudo/LabelPseudo
@onready var btn_modify_pseudo = $VBoxContainer/HBoxPseudo/BtnModifyPseudo
@onready var hbox_edit_pseudo = $VBoxContainer/HBoxEditPseudo
@onready var lineedit_pseudo  = $VBoxContainer/HBoxEditPseudo/LineEditPseudo
@onready var btn_ok_pseudo    = $VBoxContainer/HBoxEditPseudo/BtnOkPseudo
@onready var btn_reset     = $VBoxContainer/BtnReset
@onready var btn_back      = $VBoxContainer/BtnBack
@onready var label_music_percent = $VBoxContainer/HBoxMusic/LabelMusicPercent
@onready var label_sfx_percent   = $VBoxContainer/HBoxSFX/LabelSFXPercent

var available_languages = ["Français", "English", "Español"] # Modifie selon tes besoins
var settings_file = "user://settings.cfg"

func _ready():
    load_settings()
    setup_ui()
    connect_signals()
    label_music_percent.text = str(round(slider_music.value * 100)) + "%"
    label_sfx_percent.text   = str(round(slider_sfx.value * 100)) + "%"
    hbox_edit_pseudo.visible = false
    btn_modify_pseudo.pressed.connect(_on_modify_pseudo)
    btn_ok_pseudo.pressed.connect(_on_ok_pseudo)
    var pseudo = ScoreManager.load_pseudo()
func load_settings():
    var config = ConfigFile.new()
    if config.load(settings_file) == OK:
        slider_music.value = float(config.get_value("audio", "music_volume", 1.0))
        slider_sfx.value   = float(config.get_value("audio", "sfx_volume", 1.0))
        if config.has_section_key("vibration", "enabled"):
            check_vibro.button_pressed = bool(config.get_value("vibration", "enabled", true))
            config.set_value("game", "vibration", check_vibro.button_pressed)
            config.erase_section_key("vibration", "enabled")
            config.save(settings_file)
        else:
            check_vibro.button_pressed = bool(config.get_value("game", "vibration", true))
        var lang = str(config.get_value("ui", "language", "Français"))
        option_lang.selected = max(available_languages.find(lang), 0)
    else:
        slider_music.value = 1.0
        slider_sfx.value   = 1.0
        check_vibro.button_pressed = true
        option_lang.selected = 0

func save_settings():
    var config = ConfigFile.new()
    config.set_value("audio", "music_volume", slider_music.value)
    config.set_value("audio", "sfx_volume", slider_sfx.value)
    config.set_value("game", "vibration", check_vibro.button_pressed)
    config.set_value("ui", "language", available_languages[option_lang.selected])
    config.save(settings_file)

func setup_ui():
    # Langues
    option_lang.clear()
    for lang in available_languages:
        option_lang.add_item(lang)
    # Pseudo
    var pseudo = ScoreManager.load_pseudo()
    label_pseudo.text = pseudo
    hbox_edit_pseudo.visible = false
    # Applique volume audio dès le départ
    SettingsManager.set_music_volume(slider_music.value)
    SettingsManager.set_sfx_volume(slider_sfx.value)

func connect_signals():
    slider_music.value_changed.connect(_on_music_volume_changed)
    slider_sfx.value_changed.connect(_on_sfx_volume_changed)
    check_vibro.toggled.connect(_on_vibro_toggled)
    option_lang.item_selected.connect(_on_lang_selected)
    btn_modify_pseudo.pressed.connect(_on_modify_pseudo)
    btn_ok_pseudo.pressed.connect(_on_ok_pseudo)
    btn_reset.pressed.connect(_on_reset_scores)
    btn_back.pressed.connect(_on_back_pressed)

func _on_music_volume_changed(value):
    SettingsManager.set_music_volume(value)
    label_music_percent.text = str(round(value * 100)) + "%"
    save_settings()

func _on_sfx_volume_changed(value):
    SettingsManager.set_sfx_volume(value)
    label_sfx_percent.text = str(round(value * 100)) + "%"
    save_settings()

func _on_vibro_toggled(pressed):
    SettingsManager.set_vibration(pressed)
    save_settings()

func _on_lang_selected(idx):
    save_settings()
    # Tu pourras ajouter : TranslationServer.set_locale(...) plus tard

func _on_modify_pseudo():
    hbox_edit_pseudo.visible = true
    btn_modify_pseudo.visible = false
    lineedit_pseudo.text = label_pseudo.text
    lineedit_pseudo.grab_focus()
    btn_ok_pseudo.disabled = true  # Désactivé au départ

    # Important : connecte le signal si ce n'est pas déjà fait (évite double connexion)
    if not lineedit_pseudo.text_changed.is_connected(_on_edit_pseudo_text_changed):
        lineedit_pseudo.text_changed.connect(_on_edit_pseudo_text_changed)

func _on_edit_pseudo_text_changed(new_text):
    var new_pseudo = new_text.strip_edges()
    var device_id = ScoreManager.load_device_id()
    if new_pseudo == "":
        btn_ok_pseudo.disabled = true
        show_message("Merci de saisir un pseudo !")
        return

    FirestoreManager.check_pseudo_unique(new_pseudo, device_id, func(is_unique):
        if is_unique:
            btn_ok_pseudo.disabled = false
            show_message("") # tout va bien
        else:
            btn_ok_pseudo.disabled = true
            show_message("Pseudo déjà pris, choisis-en un autre !")
    )

func _on_ok_pseudo():
    var new_pseudo = lineedit_pseudo.text.strip_edges()
    if btn_ok_pseudo.disabled:
        return # Sécurité supplémentaire
    ScoreManager.save_pseudo(new_pseudo)
    label_pseudo.text = new_pseudo
    hbox_edit_pseudo.visible = false
    btn_modify_pseudo.visible = true
    show_message("Pseudo changé !")

func _on_reset_scores():
    ScoreManager.reset() # À adapter à ta logique (voir plus bas)
    show_message("Scores remis à zéro !")

func _on_back_pressed():
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func show_message(msg):
    print(msg)
    # Ou affiche dans un label temporaire si tu veux une notif

func linear_to_db(val):
    if val <= 0.01: return -80
    return 20 * log(val)
