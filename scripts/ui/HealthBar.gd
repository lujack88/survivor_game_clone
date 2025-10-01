extends Control

class_name HPBar

# UI Components
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var health_label: Label = $HealthLabel
@onready var background: NinePatchRect = $Background

# Configuration
@export var show_numbers: bool = true
@export var bar_color_full: Color = Color.GREEN
@export var bar_color_half: Color = Color.YELLOW  
@export var bar_color_low: Color = Color.RED
@export var low_health_threshold: float = 0.25
@export var half_health_threshold: float = 0.5

# Animation
@export var animate_changes: bool = true
@export var animation_duration: float = 0.2
var tween: Tween

func _ready():
	# Hide by default until connected
	visible = false
	
	# Setup progress bar
	if progress_bar:
		progress_bar.min_value = 0
		progress_bar.max_value = 100
		progress_bar.value = 100

func connect_to_health_component(health_component: HealthComponent):
	if not health_component:
		return
	
	# Connect signals
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_entity_died)
	
	# Initialize with current health
	_on_health_changed(health_component.current_health, health_component.max_health)
	
	# Show the HP bar
	visible = true

func _on_health_changed(current_health: int, max_health: int):
	if not progress_bar:
		return
	
	var health_percentage = float(current_health) / float(max_health) * 100.0
	
	# Update progress bar
	if animate_changes:
		animate_to_value(health_percentage)
	else:
		progress_bar.value = health_percentage
	
	# Update color based on health percentage
	update_bar_color(health_percentage / 100.0)
	
	# Update text
	if health_label and show_numbers:
		health_label.text = str(current_health) + "/" + str(max_health)

func animate_to_value(target_value: float):
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(progress_bar, "value", target_value, animation_duration)

func update_bar_color(health_percentage: float):
	if not progress_bar:
		return
	
	var color: Color
	
	if health_percentage <= low_health_threshold:
		color = bar_color_low
	elif health_percentage <= half_health_threshold:
		color = bar_color_half
	else:
		color = bar_color_full
	
	# Apply color to progress bar
	progress_bar.modulate = color

func _on_entity_died():
	# Optional: Add death animation or hide bar
	if animate_changes:
		var death_tween = create_tween()
		death_tween.tween_property(self, "modulate:a", 0.5, 0.3)

# Utility functions
func set_bar_size(new_size: Vector2):
	custom_minimum_size = new_size
	if progress_bar:
		progress_bar.custom_minimum_size = new_size

func show_hp_bar():
	visible = true

func hide_hp_bar():
	visible = false
