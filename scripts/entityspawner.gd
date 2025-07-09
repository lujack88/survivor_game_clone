extends Node2D

class_name EntitySpawner

@export var entity_configs: Array[EntityConfig] = []
@export var spawn_interval: float = 2.0
@export var max_entities: int = 10
@export var spawn_radius: float = 100.0

var current_entities: int = 0
var spawn_timer: Timer

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	if current_entities < max_entities and entity_configs.size() > 0:
		spawn_entity()

func spawn_entity():
	if entity_configs.is_empty():
		return
	
	# Pick random entity config
	var random_config = entity_configs[randi() % entity_configs.size()]
	if not random_config or not random_config.entity_scene:
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
	
	# Connect death signal if it exists
	if entity.has_signal("died"):
		entity.died.connect(_on_entity_died)

func _on_entity_died():
	current_entities -= 1
	current_entities = max(0, current_entities)
