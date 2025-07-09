extends Node


const MOVE_DURATION = 0.5 # How long a card takes to move to a hand
const CARD_SPACING = 80   # This visual logic now lives here
const INITIAL_DEAL_DELAY = 0.02 # Seconds between each card starting its animation
const STACK_OFFSET = 0.5 # Pixels between stacked cards to give a 3D look
const FLIP_DURATION = .15 # How long one half of the flip takes


func animate_flip(card: Node2D) -> Tween:
	var tween = card.create_tween()
	# Make the animation sequential (scale down, then callback, then scale up)
	tween.set_parallel(false) 
	
	# Scale down to appear flat
	tween.tween_property(card, "scale:x", 0, FLIP_DURATION).set_trans(Tween.TRANS_SINE)
	
	# At the moment it's flat, call the card's function to swap its texture and state
	tween.tween_callback(card.perform_visual_flip)
	
	# Scale back up to full size
	tween.tween_property(card, "scale:x", 1, FLIP_DURATION).set_trans(Tween.TRANS_SINE)
	
	return tween
	
func animate_stack_in_deck(card: Node2D, deck_marker: Marker2D, index: int) -> Tween:
	# Calculate the final position with a slight vertical offset for the stack effect
	var target_pos = deck_marker.position + Vector2(0, index * -STACK_OFFSET)
	var delay = index * INITIAL_DEAL_DELAY
	var tween = card.create_tween()		
	# The properties will animate in parallel
	tween.set_parallel()	
	# Animate the move over a short duration for a snappy feel
	tween.tween_property(card, "position", target_pos, 0.4).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(card, "rotation_degrees", 0, 0.4).set_delay(delay)
	
	return tween
	

func animate_deal_to_hand(card: Node2D, hand_parent: Node2D) -> Tween:
	_update_existing_hand_layout(hand_parent)
	var cards_in_hand = hand_parent.get_children()
	var num_cards = cards_in_hand.size()
	var total_hand_width = (num_cards - 1) * CARD_SPACING
	var start_x = -total_hand_width / 2.0
	var target_position = Vector2(start_x + (num_cards - 1) * CARD_SPACING, 0)

	var tween = card.create_tween()
	tween.set_parallel()
	tween.tween_property(card, "position", target_position, MOVE_DURATION).set_trans(Tween.TRANS_SINE)
	tween.tween_property(card, "rotation_degrees", 0, MOVE_DURATION)

	return tween
	
func _update_existing_hand_layout(hand_parent: Node2D):
	var cards = hand_parent.get_children()
	var num_cards = cards.size()
	if num_cards <= 1: return

	var total_hand_width = (num_cards - 1) * CARD_SPACING
	var start_x = -total_hand_width / 2.0

	for i in range(num_cards):
		var c = cards[i]
		var target_pos = Vector2(start_x + i * CARD_SPACING, 0)
		if c.position != target_pos:
			var tidy_tween = c.create_tween()
			tidy_tween.tween_property(c, "position", target_pos, 0.2).set_trans(Tween.TRANS_SINE)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
