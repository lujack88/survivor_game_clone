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

# HP Bar variables
var hp_bar_background: ColorRect
var hp_bar_fill: ColorRect
var hp_bar_container: Control

# Damage radius visualization
var damage_radius_circle: Control

# Player state
var last_direction := Vector2.DOWN  # Default facing down

# Damage tracking for enemies
var damaged_enemies = {}  # Dictionary to track damage timers for each enemy

func _ready() -> void:
	create_hp_bar()
	update_hp_bar()
	#create_damage_radius_circle()
	# Setup animation
	if animated_sprite:
		animated_sprite.play()
		# Create and add garlic weapon directly
	var garlic_weapon = Node2D.new()
	garlic_weapon.set_script(load("res://scripts/garlic.gd"))
	add_child(garlic_weapon)
	
	
func _physics_process(delta: float) -> void:
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
	health -= incoming_damage 
	update_hp_bar()
	print("Player health: ", health)
	if health <= 0:
		die()

func create_hp_bar():
	# Create main container for the HP bar
	hp_bar_container = Control.new()
	hp_bar_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hp_bar_container.position = Vector2(-25, -40)  # Position above sprite
	hp_bar_container.size = Vector2(50, 6)
	add_child(hp_bar_container)
	
	# Create background (red for lost health)
	hp_bar_background = ColorRect.new()
	hp_bar_background.color = Color.RED
	hp_bar_background.size = Vector2(50, 6)
	hp_bar_background.position = Vector2.ZERO
	hp_bar_container.add_child(hp_bar_background)
	
	# Create foreground (green for current health)
	hp_bar_fill = ColorRect.new()
	hp_bar_fill.color = Color.GREEN
	hp_bar_fill.size = Vector2(50, 6)
	hp_bar_fill.position = Vector2.ZERO
	hp_bar_container.add_child(hp_bar_fill)

func update_hp_bar():
	if hp_bar_fill:
		var health_percentage = float(health) / float(max_health)
		hp_bar_fill.size.x = 50 * health_percentage

func die():
	print("Player died!")
	
	# Option 1: Simple restart
	# get_tree().reload_current_scene()
	
	# Option 2: More elaborate death sequence
	# Disable player input/movement
	set_physics_process(false)
	set_process_input(false)
	
	# Hide HP bar
	if hp_bar_container:
		hp_bar_container.visible = false
	# Wait a moment then restart or show game over
	await get_tree().create_timer(2.0).timeout
	
	# Choose one of these options:
	get_tree().reload_current_scene()  # Restart level
