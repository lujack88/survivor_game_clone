extends Node

class_name LevelSystem

# XP and Level properties
@export var current_xp: int = 0
@export var current_level: int = 1
@export var xp_per_kill: int = 5

# XP requirements - Diablo 3 style (exponential growth)
var xp_requirements = []

# Signals for HUD
signal xp_changed()
signal level_up(new_level: int)

func _ready():
	# Initialize XP requirements (Diablo 3 style)
	initialize_xp_requirements()
	
	# Emit initial XP signal
	xp_changed.emit()

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
	
	# Clamp progress between 0 and 1
	var progress = float(xp_earned) / float(xp_needed)
	return clamp(progress, 0.0, 1.0)

func add_xp(amount: int):
	current_xp += amount
	xp_changed.emit()

	# Check for level up
	check_level_up()

func check_level_up():
	var required_xp = get_xp_for_next_level()
	
	while current_xp >= required_xp and required_xp > 0:
		perform_level_up()
		required_xp = get_xp_for_next_level()

func perform_level_up():
	current_level += 1

	# Emit level up signal
	level_up.emit(current_level)

	# Show level up effect
	show_level_up_effect()

func show_level_up_effect():
	# Level up effect now handled by HUD
	pass

# XP bar functions removed - now handled by HUD
