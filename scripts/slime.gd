extends CharacterBody2D

# Movement constants
const SPEED = 50
const IDLE_THRESHOLD = 5.0

# Node references (with null checks)
@onready var animated_sprite = $AnimatedSprite2D
@export var damage = 5
@export var cooldown = 1
@export var attack_radius = 20
@onready var player := $"../Player"

# Health system
var damage_text_scene = preload("res://scripts/damagetext.gd")
@export var health = 30
@export var max_health = 30
var hp_bar_background: ColorRect
var hp_bar_fill: ColorRect
var hp_bar_container: Control

# Attack timing
var attack_timer = 0.0
var can_attack = true

func _ready() -> void:
	# Add this slime to the "slimes" group so player can find it
	add_to_group("slimes")
	
	# Setup animation
	if animated_sprite:
		animated_sprite.play()
	
	# Create HP bar
	create_hp_bar()
	update_hp_bar()
		
func _physics_process(delta: float) -> void:
	# Get the global position of the player from the static variable
	var player_position = Player.global_position_ref
	var to_player = player_position - global_position
	var distance_to_player = to_player.length()
	
	# Update attack timer
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	# Attack player if in range
	if distance_to_player <= attack_radius:
		attack_player()
	
	# Check if the slime should be idle
	if distance_to_player < IDLE_THRESHOLD:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
	else:
		var direction = to_player.normalized()
		velocity = direction * SPEED
		update_animation(direction)
	
	move_and_slide()
	
func attack_player() -> void:
	if can_attack:
		# Deal damage to player
		player.take_damage(damage)
		
		# Start cooldown
		can_attack = false
		attack_timer = cooldown
		
func show_damage_text(damage_amount: int):
	var damage_text = Label.new()
	damage_text.set_script(damage_text_scene)
	get_parent().add_child(damage_text)
	var text_position = global_position + Vector2(randf_range(-15, 15), -30)
	damage_text.setup_damage_text(damage_amount, text_position, Color.ORANGE)
	
func take_damage(incoming_damage: int) -> void:
	health -= incoming_damage
	update_hp_bar()
	print("Slime took ", incoming_damage, " damage. Health: ", health)
	show_damage_text(incoming_damage)
	
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
	print("Slime died!")
	
	# Optional: Drop items, play death animation, etc.
	# $AnimationPlayer.play("death")  # if you have death animation
	# spawn_loot()  # if you want to drop items
	
	# Remove the slime from the scene
	queue_free()
			
func update_animation(direction: Vector2) -> void:
	if not animated_sprite:
		return
	
	# If not moving, play idle animation
	if direction.length() < 0.1:
		if animated_sprite.animation.contains("front"):
			animated_sprite.play("idle_front")
		elif animated_sprite.animation.contains("back"):
			animated_sprite.play("idle_back")
		else:
			animated_sprite.play("idle_side")
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
