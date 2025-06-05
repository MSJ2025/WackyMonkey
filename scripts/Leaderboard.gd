extends CanvasLayer

@onready var title_label         = $MainContainer/TitleLabel
@onready var best_label          = $MainContainer/UserBestCard/BestLabel
@onready var best_height_label   = $MainContainer/UserBestCard/BestHeightLabel
@onready var scroll_container    = $MainContainer/ScrollCont
@onready var list_container      = $MainContainer/ScrollCont/ListContainer
@onready var return_button       = $MainContainer/ReturnButton
@onready var row_template        = $MainContainer/ScrollCont/ListContainer/Panel

func _ready():
    return_button.pressed.connect(_on_return_pressed)
    afficher_online()
    _afficher_best_info()  # doit être appelé après le chargement du score local

func _on_return_pressed():
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _afficher_best_info():
    var best_score = ScoreManager.get_best_score()
    var best_height = ScoreManager.get_best_height()
    best_label.text = "🏆 Ton record : %d pts" % best_score
    best_label.add_theme_font_size_override("font_size", 54)
    best_label.add_theme_color_override("font_color", Color("#FFA900"))
    best_height_label.text = "Meilleure hauteur atteinte : %dm" % best_height
    best_height_label.add_theme_font_size_override("font_size", 42)
    best_height_label.add_theme_color_override("font_color", Color("#2EF070"))

func afficher_online():
    FirestoreManager.fetch_top_scores(func(scores):
        _afficher_scores(scores)
    )

func _afficher_scores(scores):
    # Nettoie la liste (garde seulement la ligne header et le template si besoin)
    var children = list_container.get_children()
    for child in children:
        # Garde le header (si présent) et le template invisible
        if child != row_template and not child.name.begins_with("Header"):
            child.queue_free()
    # Commence l'affichage à partir de la ligne 1
    for i in range(scores.size()):
        var entry = scores[i]
        var new_row = row_template.duplicate()
        new_row.visible = true

        var hbox = new_row.get_node("HBoxContainer")
        hbox.get_node("LabelPosition").text = str(i + 1)
        hbox.get_node("LabelPseudo").text   = entry.get("pseudo", "")
        hbox.get_node("LabelScore").text    = "%d pts" % entry.get("score", 0)
        hbox.get_node("LabelHauteur").text  = "%d m" % entry.get("best_height", 0)

        # Tu peux aussi colorer selon le rang
        # if i == 0: new_row.modulate = Color(1, 0.9, 0.2)

        list_container.add_child(new_row)
