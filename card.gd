extends Node2D

#signal hovered
#signal hovered_off

# In card.gd


# Add these @onready variables
@onready var face_texture  = $FaceSprite
@onready var back_texture = $BackSprite

var suit: String
var rank: String
var is_face_up: bool = false # Default to face down initially

# Your existing initialize function
func initialize(_suit: String, _rank: String):
	self.suit = _suit
	self.rank = _rank
	# Load the correct texture for the face, e.g.:
	face_texture.texture = load("res://CardImages/" + rank + "_of_" + suit + ".png")
	
	# Set the initial visual state without animation
	_update_visuals()

# --- THE NEW CORE LOGIC ---

# The main public function to change the card's state.
# It can be called with or without animation.
func set_is_face_up(show_face: bool, animated: bool = true):
	# Don't do anything if we're already in the desired state
	if show_face == is_face_up:
		return
		
	if animated:
		_animate_flip(show_face)
	else:
		self.is_face_up = show_face
		_update_visuals()

# A private helper to handle the actual visual change
func _update_visuals():
	face_texture.visible = is_face_up
	back_texture.visible = !is_face_up

# A private helper for the cool flip animation
func _animate_flip(show_face: bool):
	# A classic 2D flip animation: scale x to 0, swap textures, scale x back to 1.
	var tween = create_tween()
	# Scale down
	tween.tween_property(self, "scale:x", 0, 0.15).set_trans(Tween.TRANS_SINE)
	# When scaled down, call a function to swap the state and texture
	tween.tween_callback(func(): 
		self.is_face_up = show_face
		_update_visuals()
	)
	# Scale back up
	tween.tween_property(self, "scale:x", 1, 0.15).set_trans(Tween.TRANS_SINE)
		
#func _on_area_2d_mouse_entered() -> void:
	#emit_signal("hovered", self)
#
#
#func _on_area_2d_mouse_exited() -> void:
	#emit_signal("hovered_off", self)
