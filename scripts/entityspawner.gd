extends Node2D

class_name EntitySpawner

@export var entity_configs: Array[EntityConfig] = []
@export var initial_spawn_interval: float = 2.0  # Starting spawn rate
@export var max_entities: int = 10
@export var spawn_radius: float = 100.0

# ===== EXPONENTIAL SPAWN RATE CONFIGURATION =====
# Adjust these values to change the spawn rate progression
@export var spawn_acceleration_factor: float = 0.2  # Lower = faster acceleration (0.1 = very fast, 0.9 = slow)
@export var minimum_spawn_interval: float = 0.01  # Fastest possible spawn rate
@export var spawn_rate_update_interval: float = 10.0  # How often to update spawn rate (seconds)
# ================================================

var current_entities: int = 0
var spawn_timer: Timer
var spawn_rate_timer: Timer
var current_spawn_interval: float
var game_time: float = 0.0

func _ready():
	# Initialize current spawn interval
	current_spawn_interval = initial_spawn_interval
	
	print("DEBUG: EntitySpawner initializing...")
	print("DEBUG: entity_configs.size() = ", entity_configs.size())
	print("DEBUG: max_entities = ", max_entities)
	print("DEBUG: initial_spawn_interval = ", initial_spawn_interval)
	print("DEBUG: spawn_acceleration_factor = ", spawn_acceleration_factor)
	print("DEBUG: minimum_spawn_interval = ", minimum_spawn_interval)
	
	# Create and configure the spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = current_spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)
	
	# Create timer to update spawn rate periodically
	spawn_rate_timer = Timer.new()
	spawn_rate_timer.wait_time = spawn_rate_update_interval
	spawn_rate_timer.timeout.connect(_on_spawn_rate_update)
	spawn_rate_timer.autostart = true
	add_child(spawn_rate_timer)
	
	print("EntitySpawner initialized - Initial spawn rate: ", current_spawn_interval, " seconds")

func _process(delta):
	# Track game time for spawn rate calculations
	game_time += delta

func _on_spawn_timer_timeout():
	print("DEBUG: Spawn timer triggered! Current entities: ", current_entities, " Max: ", max_entities, " Configs: ", entity_configs.size())
	if current_entities < max_entities and entity_configs.size() > 0:
		spawn_entity()
	else:
		print("DEBUG: Not spawning - entities at max or no configs")

func spawn_entity():
	if entity_configs.is_empty():
		print("DEBUG: No entity configs available!")
		return
	
	# Pick random entity config
	var random_config = entity_configs[randi() % entity_configs.size()]
	if not random_config or not random_config.entity_scene:
		print("DEBUG: Invalid entity config!")
		return
	
	# Instance the entity
	var entity = random_config.entity_scene.instantiate()
	
	# Position it randomly around spawner
	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var offset = Vector2(cos(angle), sin(angle)) * distance
	entity.global_position = global_position + offset
	
	# Add to parent (world)
	get_parent().add_child(entity)
	current_entities += 1
	
	print("DEBUG: Spawned entity! Total entities: ", current_entities)
	
	# Connect death signal if it exists
	if entity.has_signal("died"):
		entity.died.connect(_on_entity_died)

func _on_entity_died():
	current_entities -= 1
	current_entities = max(0, current_entities)

func _on_spawn_rate_update():
	# ===== EXPONENTIAL SPAWN RATE CALCULATION =====
	# This is where the magic happens - adjust the formula to change progression
	var time_factor = game_time / 60.0  # Convert to minutes for easier tweaking
	var new_spawn_interval = initial_spawn_interval * pow(spawn_acceleration_factor, time_factor)
	
	# Ensure we don't go below minimum spawn rate
	new_spawn_interval = max(new_spawn_interval, minimum_spawn_interval)
	
	print("DEBUG: time_factor=", time_factor, " new_interval=", new_spawn_interval, " current_interval=", current_spawn_interval)
	
	# Update the spawn timer if rate has changed significantly
	if abs(new_spawn_interval - current_spawn_interval) > 0.01:
		current_spawn_interval = new_spawn_interval
		spawn_timer.wait_time = current_spawn_interval
		spawn_timer.start()  # Restart the timer with new interval
		print("EntitySpawner rate updated! New interval: ", current_spawn_interval, " seconds (Game time: ", int(game_time), "s)")
		print("DEBUG: Spawns per minute: ", 60.0 / current_spawn_interval)

# ===== DEBUG/UTILITY FUNCTIONS =====
# Call these functions to check current spawn rate or reset it
func get_current_spawn_rate() -> float:
	return current_spawn_interval

func get_spawns_per_minute() -> float:
	return 60.0 / current_spawn_interval

func reset_spawn_rate():
	"""Reset spawn rate to initial value - useful for testing"""
	current_spawn_interval = initial_spawn_interval
	spawn_timer.wait_time = current_spawn_interval
	spawn_timer.start()  # Restart timer
	game_time = 0.0
	print("EntitySpawner rate reset to initial value: ", current_spawn_interval, " seconds")

func debug_spawn_calculation():
	"""Debug function to test spawn rate calculation"""
	print("=== SPAWN RATE DEBUG ===")
	print("Game time: ", game_time, " seconds")
	print("Time factor: ", game_time / 60.0)
	print("Initial interval: ", initial_spawn_interval)
	print("Acceleration factor: ", spawn_acceleration_factor)
	
	var time_factor = game_time / 60.0
	var calculated_interval = initial_spawn_interval * pow(spawn_acceleration_factor, time_factor)
	var final_interval = max(calculated_interval, minimum_spawn_interval)
	
	print("Calculated interval: ", calculated_interval)
	print("Final interval (with min cap): ", final_interval)
	print("Spawns per minute: ", 60.0 / final_interval)
	print("========================")
