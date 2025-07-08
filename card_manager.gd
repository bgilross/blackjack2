extends Node2D

const SUITS = ["clubs", "diamonds", "hearts", "spades"]
const RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
var deck: Array = []
var player_hand = []
var dealer_hand = []

var players_turn = true
#dealer plus 1 player = 2.... 
var current_players = 2 

var center_screen_x

const CardScene = preload("res://card.tscn")

const PLAYER_HAND_Y_POSITION = 900 #???
const DEALER_HAND_Y_POSITION = 200 #???
const CARD_WIDTH = 200
const COLLISION_MASK_CARD = 1
#var card_being_dragged
#var is_hovering_on_card

@onready var screen_size = get_viewport_rect().size
@onready var deck_position_marker: Marker2D = $DeckPileMarker
@onready var offscreen_deal_marker: Marker2D = $OffScreenStartMarker
@onready var new_deal_button: Button = $UI/Menu/NewDeal_button
@onready var deal_button: Button = $UI/Menu/Deal_button
@onready var shuffle_button: Button = $UI/Menu/Shuffle_button
@onready var card_holder: Node2D = $CardHolder
@onready var player_hand_parent: Node2D = $PlayerHand
@onready var dealer_hand_parent: Node2D = $DealerHand

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	print("viewport size:")
	print(get_viewport().size.x)
	new_deal_button.pressed.connect(setup_deck)	
	deal_button.pressed.connect(deal_cards)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if card_being_dragged:
		#var mouse_pos = get_global_mouse_position()
		##constrain card POS so it can't go off the screen and be dropped and lost.
		#card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))	
	pass
	
func deal_cards():	
	for i in current_players * 2:
		print("i is:")
		print(i)
		print()
		if players_turn:
			add_card_to_player_hand(card_holder.get_child(0))
			players_turn = false
		else:
			add_card_to_dealers_hand(card_holder.get_child(0))
			players_turn = true
	

func add_card_to_player_hand(card):
	card.reparent(player_hand_parent)
	update_player_card_positions()
	
func add_card_to_dealers_hand(card):
	card.reparent(dealer_hand_parent)
	update_dealer_card_positions()
	
func update_player_card_positions():
	for i in range(player_hand_parent.get_child_count()):
		var new_position = Vector2(calculate_card_position(i), player_hand_parent.position.y)	
		var card = player_hand_parent.get_child(i)
		animate_card_to_position(card, new_position)
		
func update_dealer_card_positions():
	for i in range(dealer_hand_parent.get_child_count()):
		var new_position = Vector2(calculate_card_position(i), dealer_hand_parent.position.y)	
		var card = dealer_hand_parent.get_child(i)
		print("new position is:")
		print(new_position)
		animate_card_to_position(card, new_position)
	
func calculate_card_position(index):
	print("calculate card position, index is %d " % index)
	var total_width = (player_hand_parent.get_child_count() -1) * CARD_WIDTH
	
	var x_offset = player_hand_parent.global_position.x / 2 + index * CARD_WIDTH - total_width / 2
	print("x_offset")
	print(x_offset)
	
	return x_offset

func animate_card_to_position(card, new_position):
	print("animating card")
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)
	print(new_position)
	
func setup_deck():
	#clears cards and decks, 
	#creates a shuffled deck, which is the children of CardHolder, an array, 0 is the TOP card.
	print("setup deck running")
	#Clear any existing cards from the table first
	for card in get_tree().get_nodes_in_group("cards"):
		card.queue_free()
	create_deck_array() 
	shuffle_deck_array()	
	create_deck()
		
func create_deck_array():
	deck.clear()
	for suit in SUITS:
		for rank in RANKS:
			deck.append({
				"suit": suit,
				"rank": rank
			})
	print("Created a deck with %d cards." % deck.size())

func shuffle_deck_array():
	for n in 8:
		deck.shuffle()
		print("deck shuffled %d time, " % n)
		#print(deck)
		
func create_deck():
	print("creating deck")
	for i in range(deck.size()):
		#var card_data = deck.pop_front()
		var new_card = CardScene.instantiate()
		#add_child(new_card)
		card_holder.add_child(new_card)
		#new_card.initialize(card_data.suit, card_data.rank)
		new_card.initialize(deck[i].suit, deck[i].rank)
		#bogus tweening>
		#new_card.global_position = offscreen_deal_marker.global_position
		#new_card.z_index = i
		#var target_position = deck_position_marker.global_position + Vector2(0, i * -0.2)
		#
		#var tween = create_tween()
		#tween.set_trans(Tween.TRANS_CUBIC)
		#tween.set_ease(Tween.EASE_OUT)
		#tween.tween_property(new_card, "global_position", target_position, 0.2)
		animate_card_to_position(new_card, deck_position_marker.position)
	
	#var new_deck = card_holder.get_children()
	#print(new_deck.size())
	#print(new_deck)
	#var z_card = get_card_with_highest_z_index(new_deck)	
	#print(z_card)

func get_card_with_highest_z_index(cards):
	#Assume first card has highest z index
	#var highest_z_card = cards[0].collider.get_parent()
	var highest_z_card = cards[0]
	var highest_z_index = highest_z_card.z_index
	
	#loop through the rest to check for any higher Zs
	for i in range(1, cards.size()):
		var current_card = cards[i]
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
		
		
		
		
		
		
#bunch of hover/drag logic stuff.	
		
		
#detect a mouse click
#func _input(event):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed:	
			#var card = raycast_check_for_card()			
			#if card:
				#start_drag(card)
		#else:
			#if card_being_dragged:
				#finish_drag()
	
#func start_drag(card):
	#card_being_dragged = card
	#card.scale = Vector2(1, 1)
#
#func finish_drag():
	#card_being_dragged.scale = Vector2(1.05, 1.05)
	#card_being_dragged = null
	
#func connect_card_signals(card):
	#card.connect("hovered", on_hovered_over_card)
	#card.connect("hovered_off", on_hovered_off_card)
	
#func on_hovered_over_card(card):
	#if !is_hovering_on_card:
		#is_hovering_on_card = true
		#print("hovered")
		#highlight_card(card, true)
#func on_hovered_off_card(card):
	#if !card_being_dragged:
		#print("hovered off")
		##is_hovering_on_card = false
		##check if we hovered off one card and straight on to another card:
		#var new_card_hovered = raycast_check_for_card()
		#if new_card_hovered:
			#highlight_card(new_card_hovered, true)
		#else:
			#is_hovering_on_card = false
		#highlight_card(card, false)
	
#func highlight_card(card, hovered):
	#if hovered:
		#card.scale = Vector2(1.05, 1.05)
		#card.z_index = 2
	#else:
		#card.scale = Vector2(1,1)
		#card.z_index = 1

#THIS WONT WORK FOR CARD GAMES WITH HANDS>
#func get_card_with_highest_z_index(cards):
	##Assume first card has highest z index
	#var highest_z_card = cards[0].collider.get_parent()
	#var highest_z_index = highest_z_card.z_index
	#
	##loop through the rest to check for any higher Zs
	#for i in range(1, cards.size()):
		#var current_card = cards[i].collider.get_parent()
		#if current_card.z_index > highest_z_index:
			#highest_z_card = current_card
			#highest_z_index = current_card.z_index
	#return highest_z_card
	
#func raycast_check_for_card():
	#var space_state = get_world_2d().direct_space_state
	#var parameters = PhysicsPointQueryParameters2D.new()
	#parameters.position = get_global_mouse_position()
	#parameters.collide_with_areas = true
	#parameters.collision_mask = COLLISION_MASK_CARD
	#var result = space_state.intersect_point(parameters)
	#if result.size() > 0:
		##return result[0].collider.get_parent()
		#return get_card_with_highest_z_index(result)
	#return null
	
