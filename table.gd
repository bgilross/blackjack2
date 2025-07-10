extends Node2D

signal table_setup_complete

const MOVE_DURATION = 0.5 # How long a card takes to move to a hand
const CARD_SPACING = 80   # This visual logic now lives here
const INITIAL_DEAL_DELAY = 0.02 # Seconds between each card starting its animation
const STACK_OFFSET = 0.5 # Pixels between stacked cards to give a 3D look
const FLIP_DURATION = .15 # How long one half of the flip takes
const CARD_SCENE = preload("res://card.tscn")

@export var player_areas: Array[Control]

@onready var deck_marker: Node2D = $DeckMarker
@onready var spawn_node: Node2D = $SpawnPos

var visual_deck_nodes: Array = []

func animate_stack_in_deck(card: Node2D, deck_marker: Node2D, index: int) -> Tween:
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

func _create_move_tween(node_to_move: Node2D, target_position: Vector2, duration: float) -> Tween:
	var tween = create_tween()
	tween.set_parallel(true) # Allows moving and rotating at the same time if you add it
	tween.set_trans(Tween.TRANS_CUBIC) # A nice smooth curve
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(node_to_move, "position", target_position, duration)
	
	# You could add more flair here later!
	# tween.tween_property(node_to_move, "rotation_degrees", 15, duration * 0.5)
	# tween.tween_property(node_to_move, "rotation_degrees", 0, duration * 0.5).set_delay(duration * 0.5)
	
	return tween

func clear_deck():
	for card in deck_marker.get_children():
		card.queue_free()
	visual_deck_nodes.clear()
	
func setup_visual_deck(card_count: int):
	clear_deck()
	for i in range(card_count):
		var card: Node2D = CARD_SCENE.instantiate()
		add_child(card)
		card.set_face_down()
		card.position = spawn_node.position
		animate_stack_in_deck(card, deck_marker, i)
	
		
	
func hide_table():
	for area in player_areas:
		area.visible = false
		
func setup_player_areas(players_data: Array):
	var dealer_area = player_areas[0]
	dealer_area.visible = true
	dealer_area.setup("Dealer")
	
	var human_area = player_areas[1]
	human_area.visible = true
	human_area.setup(players_data[0].name)
	
	for i in range(1, players_data.size()):
		var ai_data = players_data[i]
		var ai_area_node = player_areas[i + 1] # +1 because of dealer, +1 because human is 0
		ai_area_node.visible = true
		ai_area_node.setup(ai_data.name)
		
func setup_table(players_data: Array):
	hide_table()	
	setup_player_areas(players_data)
	setup_visual_deck(52)
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
