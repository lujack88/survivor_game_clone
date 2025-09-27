extends Node

class_name PlayerStats

# Base stats with default values
@export var base_damage: float = 1.0
@export var base_attack_speed: float = 1.0
@export var base_armor: float = 0.0
@export var base_max_hp: float = 1.0

# Current stats (can be modified by upgrades, items, etc.)
var damage_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var armor_multiplier: float = 0.0
var max_hp_multiplier: float = 1.0

# Signals for when stats change
signal stats_changed
signal max_hp_increased(hp_increase: int)

func _ready():
	# Initialize current stats to base values
	reset_stats()

func reset_stats():
	damage_multiplier = base_damage
	attack_speed_multiplier = base_attack_speed
	armor_multiplier = base_armor
	max_hp_multiplier = base_max_hp
	stats_changed.emit()

# Getter functions for final stat values
func get_damage_multiplier() -> float:
	return damage_multiplier

func get_attack_speed_multiplier() -> float:
	return attack_speed_multiplier

func get_armor_reduction() -> float:
	# Armor reduces damage taken (0.0 = no reduction, 0.5 = 50% reduction, etc.)
	return clamp(armor_multiplier, 0.0, 0.9)  # Cap at 90% damage reduction

func get_max_hp_multiplier() -> float:
	return max_hp_multiplier

# Functions to modify stats (for upgrades, items, etc.)
func add_damage(amount: float):
	damage_multiplier += amount
	stats_changed.emit()

func add_attack_speed(amount: float):
	attack_speed_multiplier += amount
	stats_changed.emit()

func add_armor(amount: float):
	armor_multiplier += amount
	stats_changed.emit()

func add_max_hp(amount: float):
	# Calculate the increase in actual HP points
	var base_max_health = 100  # Store original max health
	var old_max_hp = int(base_max_health * max_hp_multiplier)

	# Apply the multiplier increase
	max_hp_multiplier += amount

	# Calculate new max HP and the difference
	var new_max_hp = int(base_max_health * max_hp_multiplier)
	var hp_increase = new_max_hp - old_max_hp

	# Emit signals
	stats_changed.emit()
	max_hp_increased.emit(hp_increase)

# Function to get stats as a dictionary for display
func get_stats_display() -> Dictionary:
	return {
		"Damage": "%.1fx" % damage_multiplier,
		"Attack Speed": "%.1fx" % attack_speed_multiplier,
		"Armor": "%d" % int(armor_multiplier * 100),
		"Max HP": "%.1fx" % max_hp_multiplier
	}