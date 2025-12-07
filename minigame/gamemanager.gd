extends Node2D

# Config: Sensational Godot Engine Headlines
var secret_words = [
	"NODE NOT FOUND AT RELATIVE PATH",
	"SIGNAL EMITTED BUT NO ONE LISTENED",
	"ILLEGAL ACCESS TO PREVIOUSLY FREED OBJECT",
	"CHARACTER BODY STUCK IN FLOOR COLLISION",
	"CYCLIC DEPENDENCY DETECTED IN SCRIPT",
]

var current_target_word = ""
var found_characters = [] # Array of unique strings found, e.g., ["A", "X", "G"]
var bugs_found_count = 0
var total_bugs = 5

# Tracking for Hints
var active_letters = [] # Stores dictionary: { "node": Area2D, "char": String }

# References
@onready var letters_root = $Letters
@onready var ui_container = $UI/MarginContainer/VBoxContainer
@onready var ui_label = $UI/MarginContainer/VBoxContainer/TargetLabel
@onready var status_label = $UI/MarginContainer/VBoxContainer/StatusLabel
@onready var newspaper_sprite = $Room # Reference to the background to get bounds
@onready var spawn_polygon_node = $Letters/allowedspawnarea # Reference to the polygon

# UI Elements created dynamically
var bug_tracker_label: Label
var hint_button: Button
var hint_line: Line2D

# Win Screen Elements
var win_overlay: ColorRect
var win_title: Label
var win_countdown: Label

# Data for polygon spawning
var polygon_triangles = []
var total_polygon_area = 0.0

# Fallback bounds if polygon is missing
var spawn_rect = Rect2(100, 100, 1700, 800)

var letter_scene_script = preload("res://minigame/microletter.gd")
var bug_scene_script = preload("res://minigame/bug.gd")

func _ready():
	randomize()
	_setup_hint_system() # Setup line and button
	_setup_bug_ui()
	_setup_win_screen() # Setup the win overlay
	_prepare_spawn_geometry()
	start_new_game()

func _setup_hint_system():
	# 1. Create the Visual Line
	hint_line = Line2D.new()
	hint_line.width = 5.0
	hint_line.default_color = Color(1, 0.8, 0, 0) # Gold, start transparent
	hint_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	hint_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	hint_line.z_index = 100 # On top of everything
	add_child(hint_line)
	
	# 2. Create the Hint Button
	var btn_container = get_node_or_null("UI/ButtonContainer")
	if not btn_container:
		btn_container = ui_container # Fallback
	
	# Ensure the container has bottom padding so the button isn't on the edge
	btn_container.add_theme_constant_override("margin_bottom", 50)
		
	hint_button = Button.new()
	hint_button.text = "Hint"
	
	# Style matching the Quit Button
	hint_button.add_theme_font_size_override("font_size", 48)
	hint_button.custom_minimum_size = Vector2(300, 100)
	hint_button.self_modulate = Color(0.0745098, 0.556863, 1, 1) # Quit Button Blue
	
	# Position: Bottom Right (Shrink End x Shrink End)
	hint_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	hint_button.size_flags_vertical = Control.SIZE_SHRINK_END
	
	hint_button.pressed.connect(_on_hint_pressed)
	
	btn_container.add_child(hint_button)

func _setup_bug_ui():
	# Create a simple label for bug progress
	bug_tracker_label = Label.new()
	bug_tracker_label.add_theme_font_size_override("font_size", 32)
	bug_tracker_label.add_theme_color_override("font_color", Color.ORANGE)
	bug_tracker_label.add_theme_color_override("font_outline_color", Color.WHITE)
	bug_tracker_label.add_theme_constant_override("outline_size", 5)
	# Add it to the UI container
	ui_container.add_child(bug_tracker_label)
	_update_bug_tracker()

func _setup_win_screen():
	# 1. Create Overlay (Dark Background)
	win_overlay = ColorRect.new()
	win_overlay.color = Color(0, 0, 0, 0.85) # Semi-transparent black
	win_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win_overlay.visible = false
	
	# Add to UI root to cover everything
	var ui_root = get_node("UI")
	ui_root.add_child(win_overlay)
	
	# 2. Center Container
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win_overlay.add_child(center)
	
	# 3. VBox for Vertical Layout
	var vbox = VBoxContainer.new()
	# FIX: Use correct API for adding constant overrides
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	# 4. Title Label
	win_title = Label.new()
	win_title.text = "HEADLINE RESTORED!"
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_title.add_theme_font_size_override("font_size", 84)
	win_title.add_theme_color_override("font_color", Color.GREEN)
	win_title.add_theme_color_override("font_outline_color", Color.WHITE)
	win_title.add_theme_constant_override("outline_size", 10)
	vbox.add_child(win_title)
	
	# 5. Countdown Label
	win_countdown = Label.new()
	win_countdown.text = "Next edition in 5..."
	win_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_countdown.add_theme_font_size_override("font_size", 48)
	vbox.add_child(win_countdown)

func _prepare_spawn_geometry():
	if not spawn_polygon_node:
		return
		
	var points = spawn_polygon_node.polygon
	if points.is_empty():
		return
		
	# Triangulate the polygon to pick random points uniformly
	var indices = Geometry2D.triangulate_polygon(points)
	
	for i in range(0, indices.size(), 3):
		var p1 = points[indices[i]]
		var p2 = points[indices[i+1]]
		var p3 = points[indices[i+2]]
		
		# Calculate area of triangle
		# Area = 0.5 * |x1(y2 - y3) + x2(y3 - y1) + x3(y1 - y2)|
		var area = 0.5 * abs(p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y))
		
		total_polygon_area += area
		# Store triangle points and the cumulative area up to this triangle
		polygon_triangles.append({
			"a": p1, 
			"b": p2, 
			"c": p3, 
			"cumulative_area": total_polygon_area
		})

func start_new_game():
	# Reset Bug Count (but preserve total_bugs increment)
	bugs_found_count = 0
	_update_bug_tracker()
	
	# Clear old letters and bugs
	for child in letters_root.get_children():
		# Don't delete the polygon itself!
		if child == spawn_polygon_node:
			continue
		child.queue_free()
	
	# Pick word and reset state
	current_target_word = secret_words.pick_random()
	found_characters = []
	active_letters.clear() # Clear tracking array
	
	update_ui()
	status_label.text = "READ THE GODOT GAZETTE..."
	status_label.modulate = Color.WHITE
	
	spawn_letters()
	spawn_bugs()

func spawn_letters():
	var unique_needed = []
	
	# 1. Identify UNIQUE characters needed for the phrase (ignore spaces)
	for char_needed in current_target_word:
		if char_needed == " ":
			continue
		if not char_needed in unique_needed:
			unique_needed.append(char_needed)
	
	# 2. Spawn ONE instance of each unique letter required
	for char_str in unique_needed:
		spawn_single_letter(char_str)

func spawn_bugs():
	for i in range(total_bugs):
		spawn_single_bug()

func get_random_position_in_polygon() -> Vector2:
	# Fallback to rect if no triangles (polygon missing or invalid)
	if polygon_triangles.is_empty():
		return Vector2(
			randf_range(spawn_rect.position.x, spawn_rect.end.x),
			randf_range(spawn_rect.position.y, spawn_rect.end.y)
		)
	
	# 1. Pick a weighted random triangle
	var r = randf() * total_polygon_area
	var selected = polygon_triangles.back() # Default to last
	
	for tri in polygon_triangles:
		if r <= tri.cumulative_area:
			selected = tri
			break
	
	# 2. Pick a random point inside that triangle
	var r1 = randf()
	var r2 = randf()
	
	# Fold the square (r1, r2) into the triangle
	if r1 + r2 > 1.0:
		r1 = 1.0 - r1
		r2 = 1.0 - r2
		
	# Barycentric coordinates -> Cartesian
	# P = A + r1*(B-A) + r2*(C-A)
	var point_local = selected.a + (selected.b - selected.a) * r1 + (selected.c - selected.a) * r2
	
	# Transform point from Polygon's local space to Letter container space
	# Since allowedspawnarea is a child of Letters, we just apply the polygon's transform
	return spawn_polygon_node.transform * point_local

func spawn_single_letter(char_str):
	# Create the Area2D/Label combo programmatically
	var area = Area2D.new()
	area.set_script(letter_scene_script)
	
	# Add Collision Shape
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 60 # Slightly smaller hit area for precision
	shape.shape = circle
	area.add_child(shape)
	
	# Add Label
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = char_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Make font huge so it scales down cleanly
	lbl.add_theme_font_size_override("font_size", 128) 
	lbl.position = Vector2(-64, -64) # Center it
	area.add_child(lbl)
	
	# Setup script
	area.setup(char_str)
	
	# Set Position using Polygon logic
	area.position = get_random_position_in_polygon()
	
	# Rotation for "messy" look (Fixed rotation)
	area.rotation = -0.1
	
	# Connect Signal
	area.letter_found.connect(_on_letter_found)
	
	letters_root.add_child(area)
	
	# Track for Hints
	active_letters.append({ "node": area, "char": char_str })

func spawn_single_bug():
	# Create the Bug Area2D programmatically
	var area = Area2D.new()
	area.set_script(bug_scene_script)
	
	# Add Collision Shape
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 60
	shape.shape = circle
	area.add_child(shape)
	
	# Add Bug Label (The emoji)
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = "🐞"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 128) 
	lbl.position = Vector2(-64, -64)
	area.add_child(lbl)
	
	# Add Status Label (Pop up text)
	var status_lbl = Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.text = "BUG FOUND!"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	# Bold font/color for visibility
	status_lbl.add_theme_font_size_override("font_size", 64) 
	status_lbl.add_theme_color_override("font_color", Color.RED)
	status_lbl.position = Vector2(-200, -150) # Position above bug
	status_lbl.visible = false # Hidden initially
	area.add_child(status_lbl)
	
	# Setup script
	area.setup()
	
	# Set Position using Polygon logic
	area.position = get_random_position_in_polygon()
	
	# Random Rotation for bugs
	area.rotation = randf_range(0, TAU)
	
	# Connect the new signal
	area.bug_found.connect(_on_bug_found)
	
	letters_root.add_child(area)

# New Signal Handler
func _on_bug_found():
	bugs_found_count += 1
	_update_bug_tracker()

func _update_bug_tracker():
	if bug_tracker_label:
		bug_tracker_label.text = "OPTIONAL BUGS: %d/%d" % [bugs_found_count, total_bugs]

func _on_hint_pressed():
	# 1. Filter for unrevealed letters
	var candidates = []
	for entry in active_letters:
		if not entry["char"] in found_characters:
			if is_instance_valid(entry["node"]):
				candidates.append(entry["node"])
	
	if candidates.is_empty():
		return
		
	# 2. Pick random
	var target_node = candidates.pick_random()
	
	# 3. Draw Line from Mouse to Target
	var start_pos = get_global_mouse_position()
	var end_pos = target_node.global_position
	
	hint_line.clear_points()
	hint_line.add_point(start_pos)
	hint_line.add_point(end_pos)
	
	# 4. Animate: Flash Visible -> Fade Out
	hint_line.default_color = Color(1, 0.8, 0, 1) # Gold visible
	
	var tween = create_tween()
	tween.tween_property(hint_line, "default_color:a", 0.0, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func update_ui():
	# Construct the display string Hangman style
	var display_text = ""
	var all_found = true
	
	for i in range(current_target_word.length()):
		var c = current_target_word[i]
		
		if c == " ":
			display_text += "   " # Triple space for word separation
		elif c in found_characters:
			display_text += c + " "
		else:
			display_text += "_ "
			all_found = false
	
	ui_label.text = display_text
	
	if all_found and current_target_word != "":
		game_won()

func _on_letter_found(char_found, letter_instance):
	# If this character is part of the secret sentence
	if char_found in current_target_word:
		# If we haven't found this letter class yet
		if not char_found in found_characters:
			found_characters.append(char_found)
			letter_instance.mark_as_found() # Visual feedback on the paper
			update_ui()
		else:
			# We already found this letter class elsewhere, but that's okay.
			# We still mark this specific instance as found for satisfaction.
			letter_instance.mark_as_found()
	else:
		# Wrong letter
		letter_instance.shake()

func game_won():
	# Increase difficulty
	total_bugs += 2
	
	# Show Win Screen
	win_overlay.visible = true
	
	# Countdown Loop
	for i in range(5, 0, -1):
		win_countdown.text = "Next printing in " + str(i) + "..."
		await get_tree().create_timer(1.0).timeout
	
	# Cleanup and Restart
	win_overlay.visible = false
	start_new_game()

func _on_quit_pressed():
	get_tree().quit()
