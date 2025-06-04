extends Node2D

@export var line_color : Color = Color("ffd700") # Or par défaut
@export var label_color : Color = Color(0,0,0)   # Noir par défaut

@onready var level_line := $LevelLine
@onready var label := $Label

func _ready():
    # Mets la couleur et ajuste la taille automatiquement
    

    
    
    label.text = "Pseudo : 0m"

func set_score(pseudo: String, score: int):
    label.text = "%s : %dm" % [pseudo, score]
    

func highlight():
    level_line.modulate = Color(1, 0.5, 0) # Flash orange
    label.modulate = Color(1, 0, 0)
