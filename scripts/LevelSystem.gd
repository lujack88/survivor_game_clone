extends Node

class_name LevelSystem

# XP and Level properties
@export var current_xp: int = 0
@export var current_level: int = 1
@export var xp_per_kill: int = 5

# XP requirements - Diablo 3 style (exponential growth)
var xp_requirements = []

# XP Bar UI elements
var xp_bar_background: ColorRect
var xp_bar_fill: ColorRect
var xp_bar_container: Control
var xp_text: Label

func _ready():
	# Initialize XP requirements (Diablo 3 style)
	initialize_xp_requirements()
	
	# Create XP bar UI
	create_xp_bar()

func initialize_xp_requirements():
	# Level 1: 25 XP, then exponential growth
	# Formula: base_xp * (level^1.5) for smooth progression
	var base_xp = 25
	for level in range(1, 100):  # Support up to level 100
		var required_xp = int(base_xp * pow(level, 1.5))
		xp_requirements.append(required_xp)

func get_xp_for_next_level() -> int:
	if current_level >= xp_requirements.size():
		return 0  # Max level reached
	return xp_requirements[current_level - 1]

func get_xp_progress() -> float:
	var current_level_xp = get_xp_for_next_level()
	if current_level_xp == 0:
		return 1.0  # Max level
	
	var previous_level_xp = 0
	if current_level > 1:
		previous_level_xp = xp_requirements[current_level - 2]
	
	var xp_needed = current_level_xp - previous_level_xp
	var xp_earned = current_xp - previous_level_xp
	
	return float(xp_earned) / float(xp_needed)

func add_xp(amount: int):
	current_xp += amount
	print("Gained ", amount, " XP! Total: ", current_xp)
	update_xp_bar()
	
	# Check for level up
	check_level_up()

func check_level_up():
	var required_xp = get_xp_for_next_level()
	
	while current_xp >= required_xp and required_xp > 0:
		level_up()
		required_xp = get_xp_for_next_level()

func level_up():
	current_level += 1
	print("LEVEL UP! You are now level ", current_level)
	
	# Show level up effect
	show_level_up_effect()
	
	# Update XP bar
	update_xp_bar()

func show_level_up_effect():
	# Create level up text
	var level_text = Label.new()
	level_text.text = "LEVEL UP! " + str(current_level)
	level_text.add_theme_font_size_override("font_size", 24)
	level_text.modulate = Color.GOLD
	
	# Position above player
	var player_pos = Player.global_position_ref
	level_text.position = player_pos + Vector2(-50, -60)
	
	# Add to scene
	get_tree().current_scene.add_child.call_deferred(level_text)
	
	# Animate and remove after 2 seconds
	var tween = create_tween()
	tween.tween_property(level_text, "position", level_text.position + Vector2(0, -50), 2.0)
	tween.tween_property(level_text, "modulate", Color.TRANSPARENT, 2.0)
	tween.tween_callback(level_text.queue_free)

func create_xp_bar():
	# Get the player node to attach XP bar to
	var player = get_parent()  # LevelSystem is a child of player
	if not player:
		return

	# Create main container for the XP bar
	xp_bar_container = Control.new()
	xp_bar_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	xp_bar_container.position = Vector2(-50, -60)  # Position above HP bar
	xp_bar_container.size = Vector2(100, 8)
	player.add_child(xp_bar_container)

	# Create background (dark for unfilled XP)
	xp_bar_background = ColorRect.new()
	xp_bar_background.color = Color(0.2, 0.2, 0.2, 0.8)
	xp_bar_background.size = Vector2(100, 8)
	xp_bar_background.position = Vector2.ZERO
	xp_bar_container.add_child(xp_bar_background)

	# Create foreground (blue for current XP)
	xp_bar_fill = ColorRect.new()
	xp_bar_fill.color = Color(0.2, 0.6, 1.0, 0.9)
	xp_bar_fill.size = Vector2(100, 8)
	xp_bar_fill.position = Vector2.ZERO
	xp_bar_container.add_child(xp_bar_fill)

	# Create XP text
	xp_text = Label.new()
	xp_text.text = "XP: " + str(current_xp) + " / " + str(get_xp_for_next_level())
	xp_text.position = Vector2(-50, -75)
	xp_text.add_theme_font_size_override("font_size", 12)
	xp_text.modulate = Color.WHITE
	player.add_child(xp_text)

func update_xp_bar():
	if not xp_bar_fill or not xp_text:
		return
	
	# Update XP bar fill
	var progress = get_xp_progress()
	xp_bar_fill.size.x = 100 * progress
	
	# Update XP text
	var next_level_xp = get_xp_for_next_level()
	if next_level_xp == 0:
		xp_text.text = "XP: " + str(current_xp) + " (MAX LEVEL)"
	else:
		xp_text.text = "XP: " + str(current_xp) + " / " + str(next_level_xp)
