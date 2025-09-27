extends CanvasLayer

class_name HUD

# UI References
@onready var health_fill: ColorRect = $HealthBar/HealthFill
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var xp_fill: ColorRect = $XPBar/XPFill
@onready var xp_label: Label = $XPBar/XPLabel
@onready var level_label: Label = $LevelLabel

# Player reference
var player: Player
var level_system: LevelSystem

func _ready():
	# Defer the connection to ensure everything is ready
	call_deferred("_connect_to_systems")

	# Set initial visibility
	visible = true

func _connect_to_systems():
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	if player:
		# Connect to player health changes
		player.connect("health_changed", _on_health_changed)

		# Get the level system from player (try by name first, then by class)
		level_system = player.get_node("LevelSystem")
		if not level_system:
			# Try to find by class type
			for child in player.get_children():
				if child.get_class() == "LevelSystem":
					level_system = child
					break

		if level_system:
			# Connect to level system changes
			level_system.connect("xp_changed", _on_xp_changed)
			level_system.connect("level_up", _on_level_up)

			# Initialize with current values
			update_health_display(player.health, player.max_health)
			update_xp_display()
			level_label.text = "Level " + str(level_system.current_level)
		else:
			# Try again in the next frame
			await get_tree().process_frame
			_connect_to_systems()
	else:
		# Try again in the next frame
		await get_tree().process_frame
		_connect_to_systems()

func _on_health_changed(current_health: int, max_health: int):
	update_health_display(current_health, max_health)

func update_health_display(current_health: int, max_health: int):
	if not health_fill or not health_label:
		return
	
	# Update health bar fill
	var health_percentage = float(current_health) / float(max_health)
	health_fill.size.x = 200 * health_percentage
	
	# Update health text
	health_label.text = str(current_health) + "/" + str(max_health)
	
	# Change color based on health percentage
	if health_percentage <= 0.25:
		health_fill.color = Color(1.0, 0.2, 0.2, 0.9)  # Red
	elif health_percentage <= 0.5:
		health_fill.color = Color(1.0, 1.0, 0.2, 0.9)  # Yellow
	else:
		health_fill.color = Color(0.2, 1.0, 0.2, 0.9)  # Green

func _on_xp_changed():
	update_xp_display()

func _on_level_up(new_level: int):
	update_xp_display()
	level_label.text = "Level " + str(new_level)
	
	# Show level up effect
	show_level_up_effect(new_level)

func update_xp_display():
	if not level_system or not xp_fill or not xp_label:
		return

	# Update XP bar fill
	var progress = level_system.get_xp_progress()
	xp_fill.size.x = 200 * progress

	# Update XP text
	var next_level_xp = level_system.get_xp_for_next_level()
	if next_level_xp == 0:
		xp_label.text = "MAX LEVEL"
	else:
		# Calculate XP needed for current level
		var previous_level_xp = 0
		if level_system.current_level > 1:
			previous_level_xp = level_system.xp_requirements[level_system.current_level - 2]

		var xp_needed = next_level_xp - previous_level_xp
		var xp_earned = level_system.current_xp - previous_level_xp

		xp_label.text = str(xp_earned) + "/" + str(xp_needed)

func show_level_up_effect(level: int):
	# Create level up text effect
	var level_up_text = Label.new()
	level_up_text.text = "LEVEL UP! " + str(level)
	level_up_text.add_theme_font_size_override("font_size", 24)
	level_up_text.modulate = Color.GOLD
	level_up_text.position = Vector2(get_viewport().size.x / 2 - 100, 100)
	
	add_child(level_up_text)
	
	# Animate and remove after 2 seconds
	var tween = create_tween()
	tween.tween_property(level_up_text, "position", level_up_text.position + Vector2(0, -50), 2.0)
	tween.tween_property(level_up_text, "modulate", Color.TRANSPARENT, 2.0)
	tween.tween_callback(level_up_text.queue_free)

# Utility functions for external access
func set_health(current: int, maximum: int):
	update_health_display(current, maximum)

func set_xp_progress(progress: float):
	if xp_fill:
		xp_fill.size.x = 200 * progress

func set_level(level: int):
	if level_label:
		level_label.text = "Level " + str(level)
