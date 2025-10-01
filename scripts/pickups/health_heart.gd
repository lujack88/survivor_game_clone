extends Area2D

class_name HealthHeart

# Heart properties
@export var heal_percentage: float = 0.15  # 15% of max health
@export var pickup_radius: float = 10.0  # Pickup collision radius
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
	collision_mask = 1   # Detect player on layer 1

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
	# Create heart sprite with PNG texture
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/objects/heart_pixel.png")
	sprite.scale = Vector2(heart_scale, heart_scale)
	add_child(sprite)

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

