extends Resource

class_name EntityConfig

@export var entity_name: String = "Slime"
@export var entity_scene: PackedScene = preload("res://scenes/slime.tscn")
@export var spawn_weight: int = 1
@export var min_player_level: int = 1
@export var max_player_level: int = 999
@export var spawn_chance: float = 1.0

func can_spawn(player_level: int = 1) -> bool:
	if player_level < min_player_level or player_level > max_player_level:
		return false
	if randf() > spawn_chance:
		return false
	return true
