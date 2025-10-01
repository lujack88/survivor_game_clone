extends Node

class_name PickupRangeBoost

# Boost properties
var boost_amount: float = 0.0
var original_pickup_range: float = 0.0
var boost_timer: Timer
var player_node: Node

func apply_boost(range_increase: float, duration: float):
	boost_amount = range_increase
	player_node = get_parent()

	# Store original pickup range and apply boost
	if player_node.has_method("get_pickup_range"):
		original_pickup_range = player_node.get_pickup_range()
	else:
		# Default pickup range if method doesn't exist
		original_pickup_range = 50.0

	# Apply the boost
	increase_pickup_range()

	# Set up timer to remove boost
	boost_timer = Timer.new()
	boost_timer.wait_time = duration
	boost_timer.one_shot = true
	boost_timer.timeout.connect(_on_boost_timeout)
	add_child(boost_timer)
	boost_timer.start()

	print("Pickup range boost applied! Range increased by ", boost_amount, " for ", duration, " seconds")

func increase_pickup_range():
	# Increase player's pickup range
	if player_node.has_method("set_pickup_range"):
		player_node.set_pickup_range(original_pickup_range + boost_amount)
	else:
		# Fallback: modify XP orb attraction ranges directly
		modify_xp_orb_attraction_globally()

func modify_xp_orb_attraction_globally():
	# Find all XP orbs and increase their magnet range
	var xp_orbs = find_all_xp_orbs()
	for orb in xp_orbs:
		if orb.has_method("set_magnet_radius"):
			orb.set_magnet_radius(orb.magnet_radius + boost_amount)
		else:
			# Direct property access
			orb.magnet_radius += boost_amount

		# Force existing orbs to check if they should now be magnetized
		force_orb_magnetism_check(orb)

func find_all_xp_orbs() -> Array:
	var xp_orbs = []

	# Try to find by group first
	var orbs_by_group = get_tree().get_nodes_in_group("xp_orbs")
	if not orbs_by_group.is_empty():
		return orbs_by_group

	# Fallback: search manually
	var all_children = get_tree().current_scene.get_children()
	for child in all_children:
		if is_xp_orb(child):
			xp_orbs.append(child)
		# Check nested children
		for grandchild in child.get_children():
			if is_xp_orb(grandchild):
				xp_orbs.append(grandchild)

	return xp_orbs

func is_xp_orb(node) -> bool:
	if node.get_script():
		var script_path = node.get_script().get_path()
		return script_path.ends_with("xp_orb.gd")
	return false

func force_orb_magnetism_check(orb):
	# Force the orb to check if it should be magnetized with the new range
	if not player_node:
		return

	var distance_to_player = orb.global_position.distance_to(player_node.global_position)

	# If orb is now within the boosted magnet range and not already magnetized
	if distance_to_player <= orb.magnet_radius and not orb.is_magnetized:
		# Activate magnetism
		if orb.has_method("start_magnetism"):
			orb.start_magnetism()
		elif orb.has_method("set_magnetized"):
			orb.set_magnetized(true)
		else:
			# Fallback: directly set the magnetized state
			orb.is_magnetized = true
			orb.target_player = player_node

func _on_boost_timeout():
	# Restore original pickup range
	restore_pickup_range()

	print("Pickup range boost expired! Range restored to normal")

	# Remove this boost effect
	queue_free()

func restore_pickup_range():
	# Restore player's original pickup range
	if player_node.has_method("set_pickup_range"):
		player_node.set_pickup_range(original_pickup_range)
	else:
		# Fallback: restore XP orb attraction ranges
		restore_xp_orb_attraction_globally()

func restore_xp_orb_attraction_globally():
	# Find all XP orbs and restore their magnet range
	var xp_orbs = find_all_xp_orbs()
	for orb in xp_orbs:
		if orb.has_method("set_magnet_radius"):
			orb.set_magnet_radius(orb.magnet_radius - boost_amount)
		else:
			# Direct property access
			orb.magnet_radius -= boost_amount

func _exit_tree():
	# Ensure boost is removed if this node is destroyed
	if player_node and is_instance_valid(player_node):
		restore_pickup_range()