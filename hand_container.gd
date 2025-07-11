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

	# Safeguard: Don't run if we haven't measured the card size yet.
	if _cached_card_size == Vector2.ZERO:
		return

	# --- DYNAMIC VALUE 1: Get width from parent ---
	# We get the width of our parent container (HandSizeTarget)
	# This ensures we always fit inside it, no matter its size.
	var max_hand_width = get_parent().size.x

	# --- DYNAMIC VALUE 2: Use the measured card size ---
	var card_width = _cached_card_size.x

	# The rest of the logic is the same!
	var ideal_total_width = (ideal_card_offset * (num_cards - 1)) + card_width
	var final_card_offset = ideal_card_offset

	if ideal_total_width > max_hand_width:
		if num_cards > 1:
			final_card_offset = (max_hand_width - card_width) / (num_cards - 1)
	
	var final_total_width = (final_card_offset * (num_cards - 1)) + card_width
	var start_x = -final_total_width / 2.0

	for i in range(num_cards):
		var card_node = cards[i]
		var new_pos = Vector2(start_x + (i * final_card_offset), 0)
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "position", new_pos, 0.25)
		
func clear_hand():
	for card in get_children():
		await card.queue_free()
		update_layout()
		


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
