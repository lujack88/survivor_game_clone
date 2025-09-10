extends Node2D

# Weapon properties
@export var damage: float = 15.0
@export var cooldown: float = 0.5
@export var projectile_speed: float = 400.0

# Internal variables
var fire_timer: Timer
var can_fire = true

func _ready():
	# Create fire timer
	fire_timer = Timer.new()
	fire_timer.wait_time = cooldown
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

func _process(_delta):
	# Check for fire input (spacebar)
	if Input.is_action_just_pressed("ui_accept") and can_fire:
		fire_projectile()

func fire_projectile():
	if not can_fire:
		return
	
	print("Firing projectile!")
	
	# Get player's position and direction
	var player_pos = Player.global_position_ref
	var player_direction = get_player_direction()
	
	print("Player pos: ", player_pos, " direction: ", player_direction)
	
	# Create projectile
	var projectile_scene = preload("res://scripts/projectile.gd")
	var projectile = CharacterBody2D.new()
	projectile.set_script(projectile_scene)
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)
	
	# Setup projectile
	projectile.setup_projectile(player_pos, player_direction)
	projectile.damage = damage
	projectile.speed = projectile_speed
	
	# Start cooldown
	can_fire = false
	fire_timer.start()

func get_player_direction() -> Vector2:
	# Get the player's last direction from the player script
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_last_direction"):
		return player.get_last_direction()
	
	# Fallback: use static reference or default direction
	return Vector2.DOWN

func _on_fire_timer_timeout():
	can_fire = true
