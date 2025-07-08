extends Node

const MOVE_DURATION = 0.5 # How long a card takes to move to a hand
const CARD_SPACING = 80   # This visual logic now lives here

func animate_initial_deck(card: Node2D, target_position: Marker2D, show_face: bool = false) -> Tween:
	
	var tween = card.create_tween()
	
	tween.set_parallel()
	tween.tween_property(card, "position", target_position.position, MOVE_DURATION * .01).set_trans(Tween.TRANS_SINE)
	tween.tween_property(card, "rotation_degrees", 0, MOVE_DURATION)
	
	return tween
	

func animate_deal_to_hand(card: Node2D, hand_parent: Node2D, show_face: bool = false) -> Tween:
	# 1. Calculate final destination (same as before)
	_update_existing_hand_layout(hand_parent) # Tidy up old cards first
	var cards_in_hand = hand_parent.get_children()
	var num_cards = cards_in_hand.size()
	var total_hand_width = (num_cards - 1) * CARD_SPACING
	var start_x = -total_hand_width / 2.0
	var target_position = Vector2(start_x + (num_cards - 1) * CARD_SPACING, 0)
	
	# 2. Create ONE tween to choreograph everything
	var tween = card.create_tween()
	
	# 3. Animate the movement properties in parallel
	tween.set_parallel()
	tween.tween_property(card, "position", target_position, MOVE_DURATION).set_trans(Tween.TRANS_SINE)
	tween.tween_property(card, "rotation_degrees", 0, MOVE_DURATION)

	# 4. If a flip is needed, schedule it with a callback
	if show_face and not card.is_face_up:
		# This will run at the same time as the movement tween
		# We create a separate sequence for the timed flip
		var flip_sequence = card.create_tween()
		flip_sequence.tween_interval(MOVE_DURATION * 0.4) # Wait a bit
		flip_sequence.tween_callback(card.set_is_face_up.bind(true, true)) # Then call the card's own flip method

	return tween

func _update_existing_hand_layout(hand_parent: Node2D):
	var cards = hand_parent.get_children()
	var num_cards = cards.size()
	if num_cards <= 1: return

	var total_hand_width = (num_cards - 1) * CARD_SPACING
	var start_x = -total_hand_width / 2.0
	
	for i in range(num_cards):
		var c = cards[i]
		# We only animate the *new* card, so we just pop the existing ones into place
		var target_pos = Vector2(start_x + i * CARD_SPACING, 0)
		if c.position != target_pos:
			# Can use a quick tween here too if you want a slick "re-shuffling" look
			var tidy_tween = c.create_tween()
			tidy_tween.tween_property(c, "position", target_pos, 0.2).set_trans(Tween.TRANS_SINE)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
