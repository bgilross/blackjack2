extends GridContainer

signal table_setup_complete

const MOVE_DURATION = 0.5 # How long a card takes to move to a hand
const CARD_SPACING = 80   # This visual logic now lives here
const INITIAL_DEAL_DELAY = 0.02 # Seconds between each card starting its animation
const STACK_OFFSET = 0.5 # Pixels between stacked cards to give a 3D look
const FLIP_DURATION = .15 # How long one half of the flip takes
const FLIP_DELAY = .4
const CARD_SCENE = preload("res://card.tscn")

@export var player_areas: Array[Control]
@onready var deck_marker: Node2D = $DeckArea/DeckPos
@onready var spawn_node: Node2D = $"../SpawnPos"
@onready var animation_layer: Node2D = $"../Animation layer"

var visual_deck_nodes: Array = []

func animate_flip(card: Control) -> Tween:
	var tween = card.create_tween()
	tween.set_parallel(false) 
	tween.tween_property(card, "scale:x", 0, FLIP_DURATION).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(card.perform_visual_flip)
	tween.tween_property(card, "scale:x", 1, FLIP_DURATION).set_trans(Tween.TRANS_SINE)
	return tween

func animate_deal_card(seat_index: int, card_data: CardData, is_face_up: bool = false):
	if visual_deck_nodes.is_empty():
		print("TABLE ERROR: No visual cards left in the deck to deal!")
		return
	var card_to_deal = visual_deck_nodes.pop_back()
	card_to_deal.setup(card_data)
	var target_area = player_areas[seat_index]
	var hand_container = target_area.get_hand_container()
	var center_marker = target_area.get_center_marker()
	var target_global_position = center_marker.global_position # Get the world position
	var move_tween = _create_move_tween(card_to_deal, target_global_position, MOVE_DURATION)
	if is_face_up:
		await get_tree().create_timer(move_tween.get_total_elapsed_time() * FLIP_DELAY).timeout
		await animate_flip(card_to_deal)
	await move_tween.finished
	card_to_deal.get_parent().remove_child(card_to_deal)
	hand_container.add_child(card_to_deal)
	hand_container.update_layout()
	
func animate_stack_in_deck(card: Control, deck_marker: Node2D, index: int) -> Tween:
	# Calculate the final position with a slight vertical offset for the stack effect
	var target_pos = deck_marker.global_position + Vector2(0, index * -STACK_OFFSET)
	var delay = index * INITIAL_DEAL_DELAY
	var tween = card.create_tween()		
	# The properties will animate in parallel
	tween.set_parallel()	
	# Animate the move over a short duration for a snappy feel
	tween.tween_property(card, "position", target_pos, 0.4).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(card, "rotation_degrees", 0, 0.4).set_delay(delay)
	
	return tween

func _create_move_tween(node_to_move: Control, target_global_position: Vector2, duration: float) -> Tween:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# --- THE FIX ---
	# Tween the node's global_position, not its local position.
	tween.tween_property(node_to_move, "global_position", target_global_position, duration)
	
	return tween
	


func clear_deck():
	for card in deck_marker.get_children():
		card.queue_free()
	visual_deck_nodes.clear()
	
func setup_visual_deck(card_count: int):
	clear_deck()
	for i in range(card_count):
		var card: Control = CARD_SCENE.instantiate()
		animation_layer.add_child(card)
		card.set_face_down()
		#card.global_position = spawn_node.position
		animate_stack_in_deck(card, deck_marker, i)
		visual_deck_nodes.append(card)
		
	
func hide_table():
	for area in player_areas:
		area.visible = false
		
func setup_player_areas(players_data: Array):
	print("table is setting up player areas: ", players_data)
	print("player area array is: ", player_areas)
	for player in players_data:
		# Get the seat index from the player's data dictionary
		var seat_idx = player.seat_index

		# Find the corresponding visual area using the seat index
		var target_area = player_areas[seat_idx]
		
		# Make it visible and set its name
		target_area.visible = true
		target_area.player_score_label.visible = true
		target_area.hand_score_label.visible = true
		target_area.setup(player.name) # Assumes PlayerArea.gd has a setup() function
		
func setup_table(players_data: Array):
	#hide_table()	
	setup_player_areas(players_data)
	await setup_visual_deck(52)
	await get_tree().create_timer(FLIP_DELAY * 3.5).timeout
	table_setup_complete.emit()
	

func update_player_score(player_index: int, new_score: int, hand_score: int):
	var target_player = player_areas[player_index]
	target_player.update_score(new_score, hand_score)
	
func add_card_to_hand(player_index: int, card_instance: Node):
	var target_player = player_areas[player_index]
	target_player.add_card(card_instance)
	
func clear_all_hands():
	for area in player_areas:
		if area.visible:
			area.clear_hand() # Assumes PlayerArea has a clear_hand() func
	
func get_area_for_player(index: int) -> Control:
	if index == -1: # -1 is our code for the dealer
		return player_areas[1]
	else:
		return player_areas[index] # Note: This assumes simple mapping. A more robust way might use player IDs.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
