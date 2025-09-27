extends CharacterBody2D

class_name Projectile

# Projectile properties
@export var speed: float = 400.0
@export var damage: float = 15.0
@export var lifetime: float = 3.0

var direction: Vector2
var damage_text_scene = preload("res://scripts/damagetext.gd")

func _ready():
	# Set up collision detection
	collision_layer = 0  # Projectile doesn't collide with anything
	collision_mask = 2   # Detect enemies (layer 1)
	
	# Create visual representation
	create_visual()
	
	# Auto-destroy after lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_timeout)
	add_child(timer)
	timer.start()

func create_visual():
	# Create a simple colored circle to represent the projectile
	var circle = ColorRect.new()
	circle.size = Vector2(8, 8)
	circle.position = Vector2(-4, -4)  # Center the circle
	circle.color = Color.YELLOW
	add_child(circle)
	
	# Create collision shape for the projectile
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 4  # Small collision area
	collision_shape.shape = circle_shape
	add_child(collision_shape)

func _physics_process(_delta):
	# Move in the set direction
	velocity = direction * speed
	move_and_slide()
	
	# Check for collisions with enemies
	var collision_count = get_slide_collision_count()
	if collision_count > 0:
		
		for i in collision_count:
			var collision = get_slide_collision(i)
			var body = collision.get_collider()
			
			# Check if it's an enemy (has take_damage function)
			if body.has_method("take_damage"):
				# Deal damage (convert to int for slime compatibility)
				body.take_damage(int(damage))
				
				# Show damage text
				show_damage_text(damage)
				
				# Destroy projectile
				queue_free()
				return

func setup_projectile(start_position: Vector2, shoot_direction: Vector2):
	global_position = start_position
	direction = shoot_direction.normalized()
	
	# Rotate projectile to face direction
	rotation = direction.angle()
	

func show_damage_text(damage_amount: float):
	var damage_text = Label.new()
	damage_text.set_script(damage_text_scene)
	get_parent().add_child(damage_text)
	var text_position = global_position + Vector2(randf_range(-10, 10), -20)
	damage_text.setup_damage_text(int(damage_amount), text_position, Color.YELLOW)

func _on_lifetime_timeout():
	queue_free()
