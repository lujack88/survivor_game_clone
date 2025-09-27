extends Node2D

# Spawner configuration
@export var slime_scene: PackedScene = preload("res://scenes/slime.tscn")
@export var spawn_interval: float = 0.1
@export var slimes_per_spawn: int = 5
@export var min_spawn_distance: float = 40
@export var max_spawn_distance: float = 75
@onready var trees: TileMapLayer = $trees

# Internal spawner variables
var spawn_timer: Timer

# Pause/Menu variables
var is_paused: bool = false
var pause_menu: PauseMenu
var pause_menu_scene = preload("res://scenes/PauseMenu.tscn")

func _ready():
	# Allow this node to process input always (including when paused for ESC key)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Ensure game starts unpaused
	get_tree().paused = false

	# Spawning now handled by EntitySpawner node
	# setup_spawner()
	create_pause_menu()

func _input(event):
	if event.is_action_pressed("pause_menu"):
		toggle_pause()

func create_pause_menu():
	# Instantiate the pause menu scene
	pause_menu = pause_menu_scene.instantiate()
	pause_menu.set_world_reference(self)
	add_child(pause_menu)

func toggle_pause():
	is_paused = !is_paused

	# Only pause the game when showing the pause menu
	if is_paused:
		pause_menu.show_menu()
		get_tree().paused = true
	else:
		pause_menu.hide_menu()
		get_tree().paused = false

func go_to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func setup_spawner():
	# Create and configure the spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	# Spawn multiple slimes at once
	for i in range(slimes_per_spawn):
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
