extends Control

class_name MainMenu

func _ready():
	# Set initial focus to play button
	$MenuContainer/PlayButton.grab_focus()

func _on_play_button_pressed():
	# Load the main game scene
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_exit_button_pressed():
	# Exit the game
	get_tree().quit()

func _input(event):
	# Allow ESC to exit from main menu
	if event.is_action_pressed("pause_menu"):
		get_tree().quit()