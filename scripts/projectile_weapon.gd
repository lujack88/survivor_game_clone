extends Node2D

# Weapon properties
@export var damage: float = 15.0
@export var cooldown: float = 0.5  # Changed to 1 second for auto-fire
@export var projectile_speed: float = 300.0
@export var auto_target_range: float = 300.0  # Range for auto-targeting

# Internal variables
var fire_timer: Timer
var can_fire = true

func _ready():
	# Set pause mode to stop processing when game is paused
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Create fire timer
	fire_timer = Timer.new()
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

	# Set initial cooldown with attack speed consideration
	update_attack_speed()

	# Start auto-firing
	fire_timer.start()

func _process(_delta):
	# Auto-fire at closest enemy if ready
	if can_fire:
		var target_enemy = find_closest_enemy()
		if target_enemy:
			fire_at_target(target_enemy)

func find_closest_enemy():
	# Get all enemies in the scene - now supports multiple enemy types dynamically
	var enemies = []
	enemies.append_array(get_tree().get_nodes_in_group("slimes"))
	# Future enemy types can be added here:
	# enemies.append_array(get_tree().get_nodes_in_group("skeletons"))
	# enemies.append_array(get_tree().get_nodes_in_group("bosses"))
	
	if enemies.is_empty():
		return null
	
	var player_pos = Player.global_position_ref
	var closest_enemy = null
	var closest_distance = auto_target_range
	
	# Find the closest enemy within range
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):  # Check if enemy still exists
			var distance = player_pos.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
	
	return closest_enemy

func fire_at_target(target_enemy):
	if not can_fire or not target_enemy:
		return
	
	# Get player's position and direction to target
	var player_pos = Player.global_position_ref
	var direction_to_target = (target_enemy.global_position - player_pos).normalized()
	
	# Create projectile
	var projectile_scene = preload("res://scripts/projectile.gd")
	var projectile = CharacterBody2D.new()
	projectile.set_script(projectile_scene)
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)
	
	# Get player stats for damage multiplier
	var player = get_tree().get_first_node_in_group("player")
	var damage_multiplier = 1.0
	if player and player.get_node_or_null("PlayerStats"):
		damage_multiplier = player.get_node("PlayerStats").get_damage_multiplier()

	# Setup projectile
	projectile.setup_projectile(player_pos, direction_to_target)
	projectile.damage = damage * damage_multiplier
	projectile.speed = projectile_speed
	
	# Start cooldown
	can_fire = false
	fire_timer.start()

# Legacy function for manual firing (kept for compatibility)
func fire_projectile():
	if not can_fire:
		return
	
	# Get player's position and direction
	var player_pos = Player.global_position_ref
	var player_direction = get_player_direction()
	
	# Create projectile
	var projectile_scene = preload("res://scripts/projectile.gd")
	var projectile = CharacterBody2D.new()
	projectile.set_script(projectile_scene)
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)
	
	# Get player stats for damage multiplier
	var player2 = get_tree().get_first_node_in_group("player")
	var damage_multiplier2 = 1.0
	if player2 and player2.get_node_or_null("PlayerStats"):
		damage_multiplier2 = player2.get_node("PlayerStats").get_damage_multiplier()

	# Setup projectile
	projectile.setup_projectile(player_pos, player_direction)
	projectile.damage = damage * damage_multiplier2
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

func update_attack_speed():
	# Get player stats for attack speed multiplier
	var player = get_tree().get_first_node_in_group("player")
	var attack_speed_multiplier = 1.0
	if player and player.get_node_or_null("PlayerStats"):
		attack_speed_multiplier = player.get_node("PlayerStats").get_attack_speed_multiplier()

	# Update timer wait time (higher attack speed = lower cooldown)
	var new_cooldown = cooldown / attack_speed_multiplier
	fire_timer.wait_time = new_cooldown
