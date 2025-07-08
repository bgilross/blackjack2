extends Node2D

signal hovered
signal hovered_off

const CARD_BACK_TEXTURE = preload("res://CardImages/CardBack.png")

var suit: String
var rank: String

var is_in_hand
var is_face_up: bool = false:
	set(value):
		if is_face_up == value:
			return
		is_face_up = value
		_update_texture()
		

@onready var card_sprite: Sprite2D = $CardSprite

#while we could handle the logic for the actual card hovering here, 
#We prefer to send it to the card manager instead. using SIGNALS>

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	##!!All cards must be a child of CardManager Node for this to work!!
	#if get_parent().has_method("connect_card_signals"):
		#get_parent().connect_card_signals(self)
	#else:
		#print("Parent missing Method connect_card_signals")
	#
	_update_texture()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if is_visible:
		##assign texture of face side of card
		#cardImage.texture = load("res://CardImages/2_of_clubs.png")
	#else:
		##assign card back texture
		#cardImage.texture = load("res://CardImages/CardBack.png")

func initialize(p_suit: String, p_rank: String):
	self.suit = p_suit
	self.rank = p_rank
	self.name = "%s_of_%s" % [rank, suit]
	_update_texture()

func _update_texture() -> void:
	if is_face_up:
		var face_texture_path = "res://CardImages/%s_of_%s.png" % [rank, suit]
		card_sprite.texture = load(face_texture_path)
	else:
		card_sprite.texture = CARD_BACK_TEXTURE
		
func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
