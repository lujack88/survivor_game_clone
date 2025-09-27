extends Node2D

class_name EntitySpawner

# Simple configuration
@export var spawn_interval: float = 0.5
@export var slimes_per_spawn: int = 1
@export var max_slimes: int = 20
@export var spawn_radius: float = 100.0

# Internal variables
var spawn_timer_elapsed: float = 0.0
var slime_scene = preload("res://scenes/slime.tscn")

func _ready():
	print("EntitySpawner ready - spawn interval: ", spawn_interval)

func _process(delta):
	# Manual timing for precise control
	spawn_timer_elapsed += delta

	if spawn_timer_elapsed >= spawn_interval:
		print("Timer triggered! Elapsed: ", spawn_timer_elapsed, " Interval: ", spawn_interval)
		spawn_timer_elapsed = 0.0
		_spawn_slime()

func _spawn_slime():
	print("Attempting to spawn ", slimes_per_spawn, " slimes")

	# Spawn multiple slimes at once
	for i in range(slimes_per_spawn):
		print("Creating slime #", i + 1)

		# Create slime
		var slime = slime_scene.instantiate()
		if not slime:
			print("Failed to instantiate slime!")
			continue

		# Random position around spawner
		var angle = randf() * TAU
		var distance = randf() * spawn_radius
		var offset = Vector2(cos(angle), sin(angle)) * distance
		slime.global_position = global_position + offset

		# Add to scene
		get_parent().add_child(slime)
		print("Added slime #", i + 1, " at position: ", slime.global_position)

	var total_slimes = get_tree().get_nodes_in_group("slimes").size()
	print("Total slimes in scene: ", total_slimes)
