extends CharacterBody2D

class_name Player

# Movement constants
const SPEED = 300.0

# Static reference for other entities (like slimes) to follow
static var global_position_ref: Vector2

# Node references (with null checks)
@onready var animated_sprite = $AnimatedSprite2D
@export var health = 100
@export var max_health = 100


# Damage text variables
var damage_text_scene = preload("res://scripts/damagetext.gd")

# Signals for HUD
signal health_changed(current_health: int, max_health: int)

# Level System
var level_system: LevelSystem

# Player Stats System
var player_stats: PlayerStats

# Damage radius visualization
var damage_radius_circle: Control

# Player state
var last_direction := Vector2.DOWN  # Default facing down

# Function to get last direction for weapons
func get_last_direction() -> Vector2:
	return last_direction

func give_xp(amount: int):
	if level_system:
		level_system.add_xp(amount)

# Damage tracking for enemies
var damaged_enemies = {}  # Dictionary to track damage timers for each enemy

func _ready() -> void:
	# Set pause mode to stop processing when game is paused
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Add player to group for weapons to find
	add_to_group("player")

	# Emit initial health signal
	health_changed.emit(health, max_health)
	
	# Create level system
	level_system = LevelSystem.new()
	level_system.name = "LevelSystem"
	add_child(level_system)

	# Create player stats system
	player_stats = PlayerStats.new()
	player_stats.name = "PlayerStats"
	add_child(player_stats)

	# Connect stats changed signal to update max health
	player_stats.stats_changed.connect(_on_stats_changed)
	player_stats.max_hp_increased.connect(_on_max_hp_increased)
	
	# Setup animation
	if animated_sprite:
		animated_sprite.play()
		# Create and add garlic weapon directly
	var garlic_weapon = Node2D.new()
	garlic_weapon.set_script(load("res://scripts/garlic.gd"))
	add_child(garlic_weapon)

	# Create and add projectile weapon
	var projectile_weapon = Node2D.new()
	projectile_weapon.set_script(load("res://scripts/projectile_weapon.gd"))
	add_child(projectile_weapon)
	
	
func _physics_process(_delta: float) -> void:
	# Update global position reference for other entities
	global_position_ref = global_position
	
	
	# Get input vector
	var input_vector := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	# If no custom input actions, fall back to default UI actions
	if input_vector == Vector2.ZERO:
		input_vector = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = input_vector * SPEED
		last_direction = input_vector
		update_animation(input_vector)
	else:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
	
	move_and_slide()
	
func update_animation(direction: Vector2) -> void:
	if not animated_sprite:
		return
	
	# If not moving, play idle animation
	if direction.length() < 0.1:
		if last_direction.length() > 0:
			# Use last direction for idle
			if abs(last_direction.x) > abs(last_direction.y):
				animated_sprite.play("idle_side")
				animated_sprite.flip_h = last_direction.x < 0
			else:
				if last_direction.y > 0:
					animated_sprite.play("idle_front")
				else:
					animated_sprite.play("idle_back")
				animated_sprite.flip_h = false
		else:
			# Default idle
			animated_sprite.play("idle_front")
	else:
		# Determine walk direction based on movement
		if abs(direction.x) > abs(direction.y):
			animated_sprite.play("walk_side")
			animated_sprite.flip_h = direction.x < 0
		else:
			if direction.y > 0:
				animated_sprite.play("walk_front")
			else:
				animated_sprite.play("walk_back")
			animated_sprite.flip_h = false

func take_damage(incoming_damage) -> void:
	# Apply armor reduction if stats system exists
	var final_damage = incoming_damage
	if player_stats:
		var armor_reduction = player_stats.get_armor_reduction()
		final_damage = int(incoming_damage * (1.0 - armor_reduction))
		final_damage = max(1, final_damage)  # Ensure at least 1 damage

	health -= final_damage
	health_changed.emit(health, max_health)

	# Create damage text
	show_damage_text(final_damage)

	if health <= 0:
		die()

# Show Damage func
func show_damage_text(damage_amount: int):
	# Create the damage text instance
	var damage_text = Label.new()
	damage_text.set_script(damage_text_scene)
	
	get_parent().add_child(damage_text)
	# Damage text color
	var text_position = global_position + Vector2(randf_range(-15, 15), -30)
	damage_text.setup_damage_text(damage_amount, text_position, Color.RED)
	
# Health bar functions removed - now handled by HUD

func die():
	print("Player died!")
	
	# Option 1: Simple restart
	# get_tree().reload_current_scene()
	
	# Option 2: More elaborate death sequence
	# Disable player input/movement
	set_physics_process(false)
	set_process_input(false)
	
	# HP bar is now handled by HUD
	# Wait a moment then restart or show game over
	await get_tree().create_timer(2.0).timeout
	
	# Choose one of these options:
	get_tree().reload_current_scene()  # Restart level

# Called when player stats change
func _on_stats_changed():
	if player_stats:
		# Update max health based on stats
		var base_max_health = 100  # Store original max health
		max_health = int(base_max_health * player_stats.get_max_hp_multiplier())

		# Ensure current health doesn't exceed new max
		health = min(health, max_health)

		# Emit health changed signal
		health_changed.emit(health, max_health)

# Called when max HP increases to heal the player
func _on_max_hp_increased(hp_increase: int):
	if player_stats:
		# Update max health based on stats
		var base_max_health = 100  # Store original max health
		max_health = int(base_max_health * player_stats.get_max_hp_multiplier())

		# Heal the player by the HP increase amount
		health += hp_increase

		# Ensure current health doesn't exceed new max
		health = min(health, max_health)

		# Emit health changed signal
		health_changed.emit(health, max_health)

		print("Max HP increased by ", hp_increase, "! Current health: ", health, "/", max_health)
