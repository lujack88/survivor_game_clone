extends Node2D

class_name EntitySpawner

# Simple configuration
@export var spawn_interval: float = 0.5
@export var slimes_per_spawn: int = 2
@export var max_slimes: int = 20

# Player-relative spawn distance configuration
@export var min_spawn_distance: float = 150.0  # Minimum distance from player
@export var max_spawn_distance: float = 500.0  # Maximum distance from player

# Internal variables
var spawn_timer_elapsed: float = 0.0
var slime_scene = preload("res://scenes/slime.tscn")

func _ready():
	# Set pause mode to stop processing when game is paused
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta):
	# Manual timing for precise control
	spawn_timer_elapsed += delta

	if spawn_timer_elapsed >= spawn_interval:
		spawn_timer_elapsed = 0.0
		_spawn_slime()

func _spawn_slime():
	# Check current slime count to respect max limit
	var current_slimes = get_tree().get_nodes_in_group("slimes").size()
	if current_slimes >= max_slimes:
		return

	# Get player position
	var player_position = Player.global_position_ref
	if player_position == Vector2.ZERO:
		# Fallback to spawner position if player not found
		player_position = global_position

	# Spawn multiple slimes at once
	for i in range(slimes_per_spawn):
		if current_slimes + i >= max_slimes:
			break

		# Create slime
		var slime = slime_scene.instantiate()
		if not slime:
			continue

		# Random position around player with configurable distance
		var angle = randf() * TAU
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		slime.global_position = player_position + offset

		# Add to scene
		get_parent().add_child(slime)
