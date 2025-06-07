extends Node

func _ready():
    var manager = preload("../managers/ScoreManager.gd").new()
    add_child(manager)
    manager.reset() # clear any existing scores
    manager.add_score("A", 10)
    manager.add_score("B", 40)
    manager.add_score("C", 30)
    print("Best score after three games:", manager.get_best_score())
    manager.add_score("D", 50)
    print("Best score after adding 50:", manager.get_best_score())
    get_tree().quit()
