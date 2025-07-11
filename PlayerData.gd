class_name PlayerData extends RefCounted

var name: String
var seat_index: int
var is_ai: bool

var hand: Array[CardData] = [] # Typed array for CardData objects!
var hand_value: int = 0
var visible_hand_value: int = 0
var score: int = 0 # This is the persistent win count
var is_busted: bool = false

# The constructor. Takes the essential info to create a player.
func _init(_name: String, _seat_index: int, _is_ai: bool):
	name = _name
	seat_index = _seat_index
	is_ai = _is_ai

# A method to handle resetting a player for a new round.
# This moves logic from the Game_Manager INTO the PlayerData class.
func reset_for_new_round():
	hand.clear()
	hand_value = 0
	visible_hand_value = 0
	is_busted = false
