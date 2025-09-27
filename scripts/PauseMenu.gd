extends CanvasLayer

class_name PauseMenu

# Node references
@onready var pause_title: Label = $MainControl/MainHBox/MenuContainer/PauseTitle
@onready var resume_button: Button = $MainControl/MainHBox/MenuContainer/ResumeButton
@onready var main_menu_button: Button = $MainControl/MainHBox/MenuContainer/MainMenuButton
@onready var stats_title: Label = $MainControl/MainHBox/StatsContainer/StatsTitle
@onready var stats_content: VBoxContainer = $MainControl/MainHBox/StatsContainer/StatsContent

# Reference to world for callbacks
var world_node: Node

func _ready():
	# Update stats display
	update_stats_display()

func set_world_reference(world: Node):
	world_node = world

func update_stats_display():
	# Clear existing stats
	for child in stats_content.get_children():
		child.queue_free()

	# Get player stats and display them
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get_node_or_null("PlayerStats"):
		var player_stats = player.get_node("PlayerStats")
		var stats_display = player_stats.get_stats_display()

		for stat_name in stats_display:
			var stat_label = Label.new()
			stat_label.text = "%s: %s" % [stat_name, stats_display[stat_name]]
			stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			stat_label.add_theme_font_size_override("font_size", 20)
			stats_content.add_child(stat_label)

			# Small spacer between stats
			var small_spacer = Control.new()
			small_spacer.custom_minimum_size = Vector2(0, 10)
			stats_content.add_child(small_spacer)

func show_menu():
	visible = true
	update_stats_display()

func hide_menu():
	visible = false

func _on_resume_button_pressed():
	if world_node and world_node.has_method("toggle_pause"):
		world_node.toggle_pause()

func _on_main_menu_button_pressed():
	if world_node and world_node.has_method("go_to_main_menu"):
		world_node.go_to_main_menu()