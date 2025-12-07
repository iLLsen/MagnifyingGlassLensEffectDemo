extends Area2D

signal letter_found(character_value, letter_instance)

@onready var label = $Label

var character: String = ""
var is_found: bool = false
# The letter will be barely visible until found
var normal_modulate = Color(0, 0, 0, 0.2) 
var found_modulate = Color(0.8, 0, 0, 1.0) # Bright red when found

func setup(char_value: String):
	character = char_value
	if label:
		label.text = character

func _ready():
	# Initial appearance: Tiny and faint
	scale = Vector2(0.1, 0.1) 
	modulate = normal_modulate
	
	if label:
		label.text = character
	
	# CRITICAL FIX: Connect the native Area2D signal to our handler function
	area_entered.connect(_on_area_entered)

# Called when the magnifier's "Focus" area enters this letter
func _on_area_entered(area):
	if is_found:
		return
		
	# We expect the area to be named "FocusPoint" or similar from the Magnifier
	if area.name == "FocusPoint":
		emit_signal("letter_found", character, self)

# Called by GameManager when this was the CORRECT letter
func mark_as_found():
	is_found = true
	modulate = found_modulate
	
	# Pop effect: Scale up momentarily then settle slightly larger
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", found_modulate, 0.2)

# Called by GameManager when this was a WRONG letter (optional feedback)
func shake():
	var tween = create_tween()
	var original_pos = position
	tween.tween_property(self, "position", original_pos + Vector2(2,0), 0.05)
	tween.tween_property(self, "position", original_pos - Vector2(2,0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)
