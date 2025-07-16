extends Label

class_name DamageText

# Properties
var float_distance: float = 50.0
var animation_duration: float = 1.0
var fade_start_time: float = 0.5

func _ready():
	# Setting initial properties
	modulate = Color.WHITE
	z_index = 100 # z index to stay on top
	
	animate_damage_text()

func setup_damage_text(damage_amount: int, start_position: Vector2, color: Color = Color.WHITE):
	# Set the damage text
	text = str(damage_amount)
	
	# Set position
	global_position = start_position
	
	# Set color
	modulate = color
	
	# Set font size based on damage (optional)
	if damage_amount > 50:
		add_theme_font_size_override("font_size", 24)
	elif damage_amount > 20:
		add_theme_font_size_override("font_size", 20)
	else:
		add_theme_font_size_override("font_size", 16)

func animate_damage_text():
	var tween = create_tween()
	tween.set_parallel(true) # simulataneous anims
	
	# Animate pos
	var start_pos = global_position
	var end_pos = start_pos + Vector2(randf_range(-20, 20), -float_distance)
	tween.tween_property(self, "global_position", end_pos, animation_duration)
	
	# Fade anim
	tween.tween_property(self, "modulate:a", 0.0, animation_duration - fade_start_time).set_delay(fade_start_time)
	
	# Impact anim
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.1)
	
	# tween call back anim
	tween.tween_callback(queue_free).set_delay(animation_duration)
