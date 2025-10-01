extends Area2D

class_name HealthHeart

# Heart properties
@export var heal_percentage: float = 0.15  # 15% of max health
@export var pickup_radius: float = 0.5  # Very small collision hitbox
@export var drop_chance: float = 0.05 	# 5% drop chance
@export var magnet_range: float = 80.0  # Range where heart is attracted to player

# Visual and physics
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var circle_shape: CircleShape2D
var tween: Tween

# Movement and animation
var is_attracted: bool = false
var attraction_speed: float = 300.0
var base_y_position: float
var heart_scale: float = 0.5

func _ready():
	# Set up collision detection
	collision_layer = 0  # Heart doesn't collide with anything
	collision_mask = 0   # Heart doesn't detect collisions automatically

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

	# No auto-destroy timer - hearts persist until picked up

func create_visual():
	# Create heart sprite
	sprite = Sprite2D.new()

	# Try to load external heart image first
	var heart_texture = load("res://assets/sprites/objects/heart_pixel.png")
	if heart_texture:
		# Use external pixel art heart
		sprite.texture = heart_texture
	else:
		# Temporary: use chest sprite as heart placeholder
		var temp_texture = load("res://assets/sprites/objects/chest_01.png")
		if temp_texture:
			sprite.texture = temp_texture
			sprite.modulate = Color.RED  # Tint it red to look more like a heart
			return
		# Fallback to generated heart
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		draw_heart_shape(image)
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture

	sprite.scale = Vector2(heart_scale, heart_scale)
	add_child(sprite)

func draw_heart_shape(image):
	var size = 32
	var center_x = size / 2.0
	var center_y = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var pixel = Vector2(x, y)
			
			# Heart shape calculation
			if is_heart_pixel(pixel, center_x, center_y):
				var distance = pixel.distance_to(Vector2(center_x, center_y))
				var normalized_distance = distance / (size / 2.0)
				
				# Create gradient from center to edge
				if normalized_distance <= 0.3:
					# Core - bright red
					image.set_pixel(x, y, Color(1.0, 0.2, 0.2, 0.95))
				elif normalized_distance <= 0.5:
					# Mid - medium red
					image.set_pixel(x, y, Color(0.9, 0.1, 0.1, 0.9))
				elif normalized_distance <= 0.7:
					# Edge - darker red
					image.set_pixel(x, y, Color(0.8, 0.0, 0.0, 0.8))
				else:
					# Outline - dark red
					image.set_pixel(x, y, Color(0.6, 0.0, 0.0, 0.7))
				
				# Add highlight
				if is_heart_highlight(pixel, center_x, center_y):
					image.set_pixel(x, y, Color(1.0, 0.6, 0.6, 1.0))

func is_heart_pixel(pixel: Vector2, center_x: float, center_y: float) -> bool:
	var x = pixel.x - center_x
	var y = pixel.y - center_y
	
	# Heart equation: (x² + y² - 1)³ ≤ x²y³
	# Simplified for pixel art
	var heart_value = pow(x * x + y * y - 1, 3) - x * x * y * y * y
	
	# Scale for pixel size
	heart_value *= 0.1
	
	return heart_value <= 0

func is_heart_highlight(pixel: Vector2, center_x: float, center_y: float) -> bool:
	var x = pixel.x - center_x
	var y = pixel.y - center_y
	
	# Highlight in upper left area of heart
	return x < -2 and y < -3 and x > -6 and y > -8

func start_animations():
	# Store base position for floating animation
	base_y_position = global_position.y
	
	# Create tween for animations
	tween = create_tween()
	tween.set_loops()  # Loop forever
	
	# Floating/bobbing animation (gentle)
	tween.tween_method(_animate_float, 0.0, 1.0, 3.0)
	tween.tween_method(_animate_float, 1.0, 0.0, 3.0)
	
	# Pulsing animation (subtle)
	tween.parallel().tween_method(_animate_pulse, 1.0, 1.1, 2.0)
	tween.parallel().tween_method(_animate_pulse, 1.1, 1.0, 2.0)

func _animate_float(t: float):
	# Only apply floating animation if not attracted
	if not is_attracted:
		# Gentle floating motion
		var offset = sin(t * PI) * 2.0
		global_position.y = base_y_position + offset

func _animate_pulse(t: float):
	# Subtle pulsing effect
	sprite.scale = Vector2(heart_scale, heart_scale) * t

func _process(delta):
	# Check for player in magnet range
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Check if player needs healing
		if not player_needs_healing(player):
			return  # Don't magnetize or pick up if player is at max HP

		var distance_to_player = global_position.distance_to(player.global_position)

		# Start attraction if player is close enough
		if distance_to_player <= magnet_range:
			is_attracted = true

		# Move towards player if attracted
		if is_attracted:
			# Stop animations when attracted
			if tween:
				tween.kill()

			var direction = (player.global_position - global_position).normalized()
			global_position += direction * attraction_speed * delta

			# Update base position for floating animation
			base_y_position = global_position.y

			# Check if close enough to pick up
			if distance_to_player <= pickup_radius:
				_pickup_heart(player)

func _on_body_entered(body):
	if body.is_in_group("player") and player_needs_healing(body):
		_pickup_heart(body)

func player_needs_healing(player) -> bool:
	# Check if player's current health is less than max health
	return player.health < player.max_health

func _pickup_heart(player):
	# Stop animations
	if tween:
		tween.kill()
	
	# Create pickup effect
	var pickup_tween = create_tween()
	pickup_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.2)
	pickup_tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 0.2)
	pickup_tween.tween_callback(_finalize_pickup.bind(player))

func _finalize_pickup(player):
	# Heal the player
	if player.has_method("heal"):
		player.heal(heal_percentage)
	elif player.has_method("get_node") and player.get_node_or_null("PlayerStats"):
		# Calculate heal amount based on max health
		var player_stats = player.get_node("PlayerStats")
		var max_hp = int(100 * player_stats.get_max_hp_multiplier())
		var heal_amount = int(max_hp * heal_percentage)

		# Add health directly
		player.health += heal_amount
		player.health = min(player.health, player.max_health)

		# Emit health changed signal
		if player.has_signal("health_changed"):
			player.health_changed.emit(player.health, player.max_health)

		print("Health heart picked up! Healed for ", heal_amount, " HP")

	# Remove the heart
	queue_free()

