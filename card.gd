extends Node2D

@onready var face_texture: Sprite2D = $FaceSprite
@onready var back_texture: Sprite2D = $BackSprite

var suit: String
var rank: String
var is_face_up: bool = false

func initialize(_suit: String, _rank: String) -> void:
	self.suit = _suit
	self.rank = _rank
	# Tip: Loading textures every time can be slow. If you have many cards,
	# consider a resource preloader script to load all textures once at startup.
	face_texture.texture = load("res://CardImages/%s_of_%s.png" % [rank, suit])
	_update_visuals()

# This function lets the GameManager determine the card's value based on game rules.
# It makes the Card node independent of any specific game (Blackjack, Poker, etc.).
func get_value() -> int:
	if rank.is_valid_int():
		return rank.to_int()
	elif rank in ["jack", "queen", "king"]:
		return 10
	elif rank == "ace":
		return 11 # The GameManager will handle reducing it to 1 if needed.
	return 0

func perform_visual_flip() -> void:
	is_face_up = !is_face_up
	_update_visuals()

func _update_visuals() -> void:
	face_texture.visible = is_face_up
	back_texture.visible = !is_face_up
