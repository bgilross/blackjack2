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
	
	# 1. Calculate the offset between cards (your logic is already great here)
	var ideal_total_width = (ideal_card_offset * (num_cards - 1)) + card_width
	var final_card_offset = ideal_card_offset

	if ideal_total_width > max_hand_width:
		if num_cards > 1:
			final_card_offset = (max_hand_width - card_width) / (num_cards - 1)

	# --- THE CENTERING FIX STARTS HERE ---

	# 2. Calculate the total width the final, spaced-out hand will occupy.
	# This is the distance from the start of the first card to the end of the last card.
	var final_total_width = (final_card_offset * (num_cards - 1)) + card_width

	# 3. Calculate the starting X position.
	# To center the group, we shift it to the left by half of its total width.
	# The container's center is at `max_hand_width / 2`.
	var start_x = (max_hand_width / 2.0) - (final_total_width / 2.0)

	# --- THE CENTERING FIX ENDS HERE ---

	# 4. Position the cards using the new start_x
	for i in range(num_cards):
		var card_node = cards[i]
		# The rest of the loop is the same!
		var new_pos = Vector2(start_x + (i * final_card_offset), 0)
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "position", new_pos, 0.25)
		


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not card_scene:
		push_error("HandContainer requires the 'card_scene' to be set in the Inspector!")
		return
		
	# Create a temporary, invisible instance of the card to measure it.
	var temp_card = card_scene.instantiate()
	_cached_card_size = temp_card.size
	# We're done with it, so free it immediately.
	temp_card.queue_free()

	print("HandContainer initialized. Detected card size: ", _cached_card_size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
