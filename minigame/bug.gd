extends Area2D

# Add signal to notify the game manager
signal bug_found

var is_fleeing = false
var speed = 150.0 # Reduced speed for "tippy toe" feel
var time_alive = 0.0
var screen_rect: Rect2

@onready var label = $Label
@onready var status_label = $StatusLabel

func setup():
	# Initial appearance: Tiny and faint
	scale = Vector2(0.1, 0.1) 
	modulate = Color(1, 1, 1, 0.2) # Ghostly
	# Random initial rotation
	rotation = randf_range(0, TAU)

func _ready():
	# Connect signal for detection
	area_entered.connect(_on_area_entered)
	# Get screen bounds for fleeing logic
	screen_rect = get_viewport_rect()

func _process(delta):
	if is_fleeing:
		flee_behavior(delta)

func flee_behavior(delta):
	time_alive += delta
	
	# 1. Base Direction: Away from screen center
	var center = screen_rect.get_center()
	var direction_to_edge = (global_position - center).normalized()
	
	# 2. Sine Wave Modulation (Smooth wandering)
	# Calculate a vector perpendicular to the fleeing direction
	var perpendicular = Vector2(-direction_to_edge.y, direction_to_edge.x)
	# Oscillate back and forth
	var wave = sin(time_alive * 10.0) * 0.5 
	
	# Combine vectors for smooth curving path
	var move_direction = (direction_to_edge + (perpendicular * wave)).normalized()
	
	# Move
	position += move_direction * speed * delta
	
	# Rotate the BUG to face direction
	# We add PI/2 because the emoji/sprite usually faces 'up' by default in text
	rotation = move_direction.angle() + (PI / 2)
	
	# Remove if off screen (with padding)
	if not screen_rect.grow(100).has_point(global_position):
		queue_free()

func _on_area_entered(area):
	if is_fleeing:
		return
		
	# We expect the area to be named "FocusPoint" from the Magnifier
	if area.name == "FocusPoint":
		start_fleeing()

func start_fleeing():
	is_fleeing = true
	
	# Notify listeners (GameManager) that this bug was found
	bug_found.emit()
	
	# Visual Pop
	modulate = Color(1, 1, 1, 1.0) # Fully visible
	
	# Tween scale up
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.25, 0.25), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Handle "BUG FOUND" text
	if status_label:
		status_label.visible = true
		
		# CRITICAL FIX: Detach the text from the bug's rotation/movement
		# Store current global pos before detaching
		var current_global_pos = status_label.global_position
		status_label.top_level = true
		status_label.global_position = current_global_pos
		status_label.rotation = 0 # Force upright
		
		# Float the text up slightly in place (it won't follow the bug anymore)
		var text_tween = create_tween()
		text_tween.tween_property(status_label, "global_position", current_global_pos + Vector2(0, -100), 1.0)
		text_tween.parallel().tween_property(status_label, "modulate:a", 0.0, 1.0) # Fade out
