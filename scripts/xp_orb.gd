extends Area2D

class_name XPOrb

# XP orb properties
@export var xp_value: int = 5
@export var move_speed: float = 200.0
@export var pickup_radius: float = 20.0
@export var magnet_radius: float = 80.0  # Radius at which orb starts moving toward player
@export var orb_scale: float = 0.9  # 25% reduction from 1.2 to 0.9

# Visual components
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var circle_shape: CircleShape2D
var tween: Tween

# State
var is_being_collected: bool = false
var is_magnetized: bool = false
var target_player: Node2D = null
var base_y_position: float
var velocity: Vector2 = Vector2.ZERO

func _ready():
	# Set up collision detection for player pickup
	collision_layer = 0    # This orb doesn't block anything
	collision_mask = 1     # Detect player on layer 1 (player layer)

	# Create visual sprite
	sprite = Sprite2D.new()
	add_child(sprite)

	# Create collision shape for pickup detection
	collision_shape = CollisionShape2D.new()
	circle_shape = CircleShape2D.new()
	circle_shape.radius = pickup_radius
	collision_shape.shape = circle_shape
	add_child(collision_shape)

	# Connect signals
	body_entered.connect(_on_body_entered)

	# Create enhanced visual
	create_visual()
	
	# Start animations
	start_animations()

func create_visual():
	# Create a more detailed and appealing orb texture
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var center = Vector2(12, 12)

	# Draw the orb with gradient and glow effects
	for x in range(24):
		for y in range(24):
			var distance = Vector2(x - center.x, y - center.y).length()
			var angle = Vector2(x - center.x, y - center.y).angle()
			
			if distance <= 8:
				# Core orb with gradient
				var gradient_factor = 1.0 - (distance / 8.0)
				
				# Add some color variation based on angle
				var color_shift = sin(angle * 2.0) * 0.1
				var r = 0.1 + color_shift
				var g = 0.8 + (gradient_factor * 0.2)
				var b = 1.0
				var a = 0.9 + (gradient_factor * 0.1)
				
				image.set_pixel(x, y, Color(r, g, b, a))
			elif distance <= 10:
				# Inner glow
				var glow_factor = 1.0 - ((distance - 8) / 2.0)
				image.set_pixel(x, y, Color(0.2, 0.6, 1.0, 0.4 * glow_factor))
			elif distance <= 12:
				# Outer glow
				var outer_glow = 1.0 - ((distance - 10) / 2.0)
				image.set_pixel(x, y, Color(0.1, 0.4, 0.8, 0.2 * outer_glow))

	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture
	sprite.scale = Vector2(orb_scale, orb_scale)

func start_animations():
	# Store base position for floating animation
	base_y_position = global_position.y
	
	# Create tween for animations
	tween = create_tween()
	tween.set_loops()  # Loop forever
	
	# Floating/bobbing animation
	tween.tween_method(_animate_float, 0.0, 1.0, 2.0)
	tween.tween_method(_animate_float, 1.0, 0.0, 2.0)
	
	# Pulsing glow animation
	tween.parallel().tween_method(_animate_pulse, 1.0, 1.3, 1.5)
	tween.parallel().tween_method(_animate_pulse, 1.3, 1.0, 1.5)

func _animate_float(t: float):
	# Only apply floating animation if not magnetized
	if not is_magnetized:
		# Smooth floating motion using sine wave
		var offset = sin(t * PI) * 3.0
		global_position.y = base_y_position + offset

func _animate_pulse(t: float):
	# Pulsing scale effect
	sprite.scale = Vector2(orb_scale, orb_scale) * t

func _physics_process(delta):
	if is_being_collected:
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	# Check for pickup
	if distance <= pickup_radius:
		collect_orb(player)
		return

	# Check for magnetic attraction - once magnetized, stay magnetized
	if distance <= magnet_radius and not is_magnetized:
		start_magnetism()

	# If magnetized, always move toward player regardless of distance
	if is_magnetized:
		# Move toward player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed

		# Apply movement
		global_position += velocity * delta

		# Update base position for floating animation
		base_y_position = global_position.y
	else:
		# Not magnetized, stay still
		velocity = Vector2.ZERO

func start_magnetism():
	is_magnetized = true

	# Stop floating animation and switch to magnetized behavior
	if tween:
		tween.kill()

	# Create a more intense pulse effect when magnetized
	tween = create_tween()
	tween.set_loops()
	tween.tween_method(_animate_pulse, 1.0, 1.4, 0.3)
	tween.tween_method(_animate_pulse, 1.4, 1.0, 0.3)

# stop_magnetism() removed - orbs stay magnetized once activated

func _on_body_entered(body):
	# Check if it's the player
	if body.is_in_group("player") and not is_being_collected:
		collect_orb(body)

func collect_orb(player):
	if is_being_collected:
		return

	is_being_collected = true

	# Stop animations
	if tween:
		tween.kill()

	# Create collection effect
	var collect_tween = create_tween()
	collect_tween.tween_property(sprite, "scale", Vector2(0.0, 0.0), 0.2)
	collect_tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 0.2)
	collect_tween.tween_callback(_finalize_collection.bind(player))

func _finalize_collection(player):
	# Give XP to player
	if player.has_method("give_xp"):
		player.give_xp(xp_value)

	# Remove the orb
	queue_free()
