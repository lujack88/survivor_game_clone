extends Area2D

class_name MagnetDrop

# Magnet properties
@export var pickup_radius: float = 30.0
@export var drop_chance: float = 0.5  # 50% drop chance
@export var magnet_range: float = 80.0  # Range where magnet is attracted to player
@export var pickup_range_increase: float = 15000.0  # How much to increase player's pickup range
@export var effect_duration: float = 1.0  # How long the effect lasts in seconds

# Visual and physics
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var circle_shape: CircleShape2D
var tween: Tween

# Movement and animation
var is_attracted: bool = false
var attraction_speed: float = 300.0
var base_y_position: float
var magnet_scale: float = 0.5

func _ready():
	# Set up collision detection
	collision_layer = 0  # Magnet doesn't collide with anything
	collision_mask = 0   # Magnet doesn't detect collisions automatically

	# Connect signals
	body_entered.connect(_on_body_entered)

	# Create visual representation
	create_visual()

	# Create collision shape
	collision_shape = CollisionShape2D.new()
	circle_shape = CircleShape2D.new()
	circle_shape.radius = pickup_radius
	collision_shape.shape = circle_shape
	add_child(collision_shape)

	# Start animations
	start_animations()

func create_visual():
	# Create magnet sprite
	sprite = Sprite2D.new()

	# Try to load external magnet image first
	var magnet_texture = load("res://assets/sprites/objects/magnet.png")
	if magnet_texture:
		# Use external magnet sprite
		sprite.texture = magnet_texture
	else:
		# Fallback to generated magnet shape
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		draw_magnet_shape(image)
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture

	sprite.scale = Vector2(magnet_scale, magnet_scale)
	add_child(sprite)

func draw_magnet_shape(image):
	var size = 32
	var center_x = size / 2.0
	var center_y = size / 2.0

	for x in range(size):
		for y in range(size):
			var pixel_x = x
			var pixel_y = y

			# Draw U-shaped magnet
			var rel_x = pixel_x - center_x
			var rel_y = pixel_y - center_y

			# Main body of magnet (vertical bars)
			if (abs(rel_x) >= 8 and abs(rel_x) <= 12) or (abs(rel_y) >= 10 and abs(rel_y) <= 14 and abs(rel_x) <= 12):
				# Alternate red and blue for magnet poles
				if rel_x < 0:
					image.set_pixel(pixel_x, pixel_y, Color.RED)  # Left side - red
				else:
					image.set_pixel(pixel_x, pixel_y, Color.BLUE)  # Right side - blue
			# Connector at bottom
			elif abs(rel_y) >= 10 and abs(rel_y) <= 12 and abs(rel_x) <= 12:
				image.set_pixel(pixel_x, pixel_y, Color.GRAY)

func start_animations():
	# Store base position for floating animation
	base_y_position = global_position.y

	# Create tween for animations
	tween = create_tween()
	tween.set_loops()  # Loop forever

	# Floating/bobbing animation (gentle)
	tween.tween_method(_animate_float, 0.0, 1.0, 2.5)
	tween.tween_method(_animate_float, 1.0, 0.0, 2.5)

	# Spinning animation
	tween.parallel().tween_method(_animate_spin, 0.0, 360.0, 4.0)

func _animate_float(t: float):
	# Only apply floating animation if not attracted
	if not is_attracted:
		# Gentle floating motion
		var offset = sin(t * PI) * 3.0
		global_position.y = base_y_position + offset

func _animate_spin(degrees: float):
	# Spinning effect
	sprite.rotation_degrees = degrees

func _process(delta):
	# Check for player in magnet range
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)

		# Start attraction if player is close enough
		if distance_to_player <= magnet_range:
			is_attracted = true

		# Move towards player if attracted
		if is_attracted:
			# Stop floating animation when attracted
			if tween:
				tween.kill()
				# Keep only the spinning animation
				tween = create_tween()
				tween.set_loops()
				tween.tween_method(_animate_spin, 0.0, 360.0, 2.0)  # Faster spin when attracted

			var direction = (player.global_position - global_position).normalized()
			global_position += direction * attraction_speed * delta

			# Update base position for floating animation
			base_y_position = global_position.y

			# Check if close enough to pick up
			if distance_to_player <= pickup_radius:
				_pickup_magnet(player)

func _on_body_entered(body):
	if body.is_in_group("player"):
		_pickup_magnet(body)

func _pickup_magnet(player):
	# Stop animations
	if tween:
		tween.kill()

	# Create pickup effect
	var pickup_tween = create_tween()
	pickup_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.2)
	pickup_tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 0.2)
	pickup_tween.tween_callback(_finalize_pickup.bind(player))

func _finalize_pickup(player):
	# Apply pickup range boost to player
	apply_pickup_range_boost(player)

	print("Magnet used! Player pickup range increased by ", pickup_range_increase, " for ", effect_duration, " seconds")

	# Remove the magnet
	queue_free()

func apply_pickup_range_boost(player):
	# Check if player has a pickup range boost system
	if player.has_method("apply_pickup_range_boost"):
		player.apply_pickup_range_boost(pickup_range_increase, effect_duration)
	else:
		# Fallback: add the boost system if it doesn't exist
		add_pickup_boost_to_player(player)

func add_pickup_boost_to_player(player):
	# Create a temporary effect node to handle the pickup range boost
	var boost_effect = Node.new()
	boost_effect.name = "PickupRangeBoost"
	boost_effect.set_script(preload("res://scripts/pickups/pickup_range_boost.gd"))

	player.add_child(boost_effect)
	boost_effect.apply_boost(pickup_range_increase, effect_duration)