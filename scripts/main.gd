extends Control

func _ready() -> void:
	print("Main scene loaded, transitioning to Menu...")
	get_tree().change_scene_to_file.call_deferred("res://scenes/Menu.tscn")
