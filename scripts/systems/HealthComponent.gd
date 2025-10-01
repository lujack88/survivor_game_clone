extends Node

class_name HealthComponent

# Signals
signal health_changed(current_health: int, max_health: int)
signal health_depleted
signal died

# Health properties
@export var max_health: int = 100
@export var current_health: int = 100
@export var regeneration_rate: float = 0.0  # HP per second
@export var invulnerable_time: float = 0.0  # Seconds of invulnerability after taking damage

# Internal variables
var is_invulnerable: bool = false
var invulnerable_timer: Timer
var regen_timer: Timer

func _ready():
	# Set current health to max if not already set
	if current_health <= 0:
		current_health = max_health
	
	# Setup invulnerability timer
	if invulnerable_time > 0:
		invulnerable_timer = Timer.new()
		invulnerable_timer.wait_time = invulnerable_time
		invulnerable_timer.one_shot = true
		invulnerable_timer.timeout.connect(_on_invulnerable_timer_timeout)
		add_child(invulnerable_timer)
	
	# Setup regeneration timer
	if regeneration_rate > 0:
		regen_timer = Timer.new()
		regen_timer.wait_time = 1.0  # Regenerate every second
		regen_timer.timeout.connect(_on_regen_timer_timeout)
		add_child(regen_timer)
		regen_timer.start()

func take_damage(amount: int):
	if is_invulnerable or current_health <= 0:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	
	# Emit health changed signal
	health_changed.emit(current_health, max_health)
	
	# Start invulnerability period
	if invulnerable_timer and invulnerable_time > 0:
		is_invulnerable = true
		invulnerable_timer.start()
	
	# Check if dead
	if current_health <= 0:
		health_depleted.emit()
		died.emit()

func heal(amount: int):
	if current_health <= 0:
		return
	
	current_health += amount
	current_health = min(max_health, current_health)
	
	health_changed.emit(current_health, max_health)

func set_max_health(new_max: int):
	max_health = new_max
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func is_alive() -> bool:
	return current_health > 0

func kill():
	current_health = 0
	health_depleted.emit()
	died.emit()

func _on_invulnerable_timer_timeout():
	is_invulnerable = false

func _on_regen_timer_timeout():
	if regeneration_rate > 0 and current_health < max_health and current_health > 0:
		heal(int(regeneration_rate))
