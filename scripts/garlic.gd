extends Node2D

# Export variables for easy tweaking in the editor
@export var dmg: float = 10.0
@export var cooldown: float = 1.0
@export var radius: float = 100.0

# Internal variables
var damage_timer: Timer
var area_2d: Area2D
var collision_shape: CollisionShape2D
var circle_shape: CircleShape2D
var redraw_timer: Timer
func _ready():
	# Create the Area2D for detection
	area_2d = Area2D.new()
	add_child(area_2d)
	
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	collision_shape.shape = circle_shape
	area_2d.add_child(collision_shape)
	
	# Set up the area to detect bodies on layer 1 (mobs)
	area_2d.collision_layer = 0  # This weapon doesn't collide with anything
	area_2d.collision_mask = 2   # Detect bodies on layer 1 (mobs)
	
	# Create and configure the damage timer
	damage_timer = Timer.new()
	damage_timer.wait_time = cooldown
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	damage_timer.autostart = true
	add_child(damage_timer)
	
	# Update radius
	circle_shape.radius = radius
	
		# Create high-frequency redraw timer
	redraw_timer = Timer.new()
	redraw_timer.wait_time = 0.003333  # 3.33ms = 300 times per second
	redraw_timer.timeout.connect(_on_redraw_timer)
	redraw_timer.autostart = true
	add_child(redraw_timer)

func _process(_delta):
	# Follow the player position
	global_position = Player.global_position_ref
	
func _draw():
	# Draw dark grey semi-transparent circle
	draw_circle(Vector2.ZERO, radius, Color(0.3, 0.3, 0.3, 0.5))

func _on_damage_timer_timeout():
	# Get all mobs currently in the area
	var bodies_in_area = area_2d.get_overlapping_bodies()
	
	# Damage each mob
	for body in bodies_in_area:
		body.take_damage(dmg)
		
func _on_redraw_timer():
	queue_redraw()
