extends Node2D

@onready var face_texture  = $FaceSprite
@onready var back_texture = $BackSprite

var suit: String
var rank: String
var is_face_up: bool = false
var value: int

func initialize(_suit: String, _rank: String):
	self.suit = _suit
	self.rank = _rank
	face_texture.texture = load("res://CardImages/" + rank + "_of_" + suit + ".png")	
	# Set the initial visual state without animation
	_update_visuals()
	set_value()

func set_value():
	if rank.is_valid_int():
		value = rank.to_int()
	elif rank in ["jack", "queen", "king"]:
		value = 10
	elif rank == "ace":
		self.value = 11

func is_ace() -> bool:
	return rank == "ace"		
	
func set_is_face_up(show_face: bool, animated: bool = true):
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

func _animate_flip(show_face: bool):
	var tween = create_tween()
	tween.tween_property(self, "scale:x", 0, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): 
		self.is_face_up = show_face
		_update_visuals()
	)
	tween.tween_property(self, "scale:x", 1, 0.15).set_trans(Tween.TRANS_SINE)
		
#func _on_area_2d_mouse_entered() -> void:
	#emit_signal("hovered", self)
#
#
#func _on_area_2d_mouse_exited() -> void:
	#emit_signal("hovered_off", self)
