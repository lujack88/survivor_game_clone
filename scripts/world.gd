extends Node2D

# Spawner configuration
@export var slime_scene: PackedScene = preload("res://scenes/slime.tscn")
@export var spawn_interval: float = 2.0
@export var min_spawn_distance: float = 40
@export var max_spawn_distance: float = 75
@onready var trees: TileMapLayer = $trees

# Internal spawner variables
var spawn_timer: Timer

func _ready():
	setup_spawner()
	

func setup_spawner():
	# Create and configure the spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	var slime = slime_scene.instantiate()
	slime.global_position = get_spawn_position_around_player()
	# This adds slime as a direct child to the current scene.
	trees.add_child(slime)

func get_spawn_position_around_player() -> Vector2:
	var player_pos = Player.global_position_ref
	var angle = randf() * TAU
	var distance = randf_range(min_spawn_distance, max_spawn_distance)
	var spawn_offset = Vector2(cos(angle), sin(angle)) * distance
	var spawn_position = player_pos + spawn_offset
	return spawn_position
