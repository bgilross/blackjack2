extends Control

@export var overlap_ratio: float = .5
@onready var card_scene = preload("res://card.tscn")
@export var ideal_card_offset: float = 40.0 

var _cached_card_size: Vector2

func update_layout():
	var cards = get_children()
	var num_cards = cards.size()
	if num_cards == 0:
		return
	if _cached_card_size == Vector2.ZERO:
		return
	var max_hand_width = get_parent().size.x
	var card_width = _cached_card_size.x	

	var ideal_total_width = (ideal_card_offset * (num_cards - 1)) + card_width
	var final_card_offset = ideal_card_offset
	if ideal_total_width > max_hand_width:
		if num_cards > 1:
			final_card_offset = (max_hand_width - card_width) / (num_cards - 1)
	
	var final_total_width = (final_card_offset * (num_cards - 1)) + card_width
	var start_x = (max_hand_width / 2.0) - (final_total_width / 2.0)
	for i in range(num_cards):
		var card_node = cards[i]
		# The rest of the loop is the same!
		var new_pos = Vector2(start_x + (i * final_card_offset), 0)
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "position", new_pos, 0.25)

func measure_card():
	if not card_scene:
		push_error("HandContainer requires the 'card_scene' to be set in the Inspector!")
		return
	var temp_card = card_scene.instantiate()
	_cached_card_size = temp_card.size
	temp_card.queue_free()
	
func _ready() -> void:
	measure_card()
