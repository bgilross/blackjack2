extends Control

@export var overlap_ratio: float = .5

func update_layout():
	#get current children aka cards
	var current_hand = get_children()
	if current_hand.is_empty():
		return
	
	#get current card size...
	var card_size = current_hand[0].size
	var card_offset_x = card_size.x * (1.0 - overlap_ratio)
	var total_width = (card_offset_x * (current_hand.size() - 1)) + card_size.x
	var start_x = -total_width / 2.0
	
	for i in range(current_hand.size()):
		var card_node = current_hand[i]		
		
		var new_pos = Vector2()		
		new_pos.x = start_x + (i * card_offset_x)
		new_pos.y = 0
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD) # Gives a nice ease-out effect
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "position", new_pos, 0.2) # Animate over 0.2 seconds
		
func clear_hand():
	for card in get_children():
		await card.queue_free()
		update_layout()
		


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
