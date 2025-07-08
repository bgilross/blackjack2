extends Node2D

const SUITS = ["clubs", "diamonds", "hearts", "spades"]
const RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
var deck: Array = []

const CardScene = preload("res://card.tscn")

const COLLISION_MASK_CARD = 1
var card_being_dragged
var is_hovering_on_card

@onready var screen_size = get_viewport_rect().size
@onready var deck_position_marker: Marker2D = $DeckPileMarker
@onready var offscreen_deal_marker: Marker2D = $OffScreenStartMarker
@onready var new_deal_button: Button = $UI/Menu/NewDeal_button
@onready var deal_button: Button = $UI/Menu/Deal_button
@onready var shuffle_button: Button = $UI/Menu/Shuffle_button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_deal_button.pressed.connect(new_deal)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		#constrain card POS so it can't go off the screen and be dropped and lost.
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))	
	
func new_deal():
	# Optional: Clear any existing cards from the table first
	for card in get_tree().get_nodes_in_group("cards"):
		card.queue_free()

	# Note the typo fix: create_deack -> create_deck
	create_deck() 
	shuffle_deck()
	
	#animate deck creationg, sliding cards over from off screen to the deal point.
	for i in range(deck.size()):
		# ... (rest of the card creation logic is the same) ...
		var card_data = deck.pop_front()
		var new_card = CardScene.instantiate()
		add_child(new_card)
		new_card.initialize(card_data.suit, card_data.rank)
		
		new_card.global_position = offscreen_deal_marker.global_position
		new_card.z_index = i
		var target_position = deck_position_marker.global_position + Vector2(0, i * -0.2)
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(new_card, "global_position", target_position, 0.2)
		

		
func create_deck():
	deck.clear()
	for suit in SUITS:
		for rank in RANKS:
			deck.append({
				"suit": suit,
				"rank": rank
			})
	print("Created a deck with %d cards." % deck.size())


	## We iterate through a copy of the deck data, so we don't destroy our main deck array
	#var deck_to_animate = deck.duplicate()
	#for i in range(deck_to_animate.size()):
		#var card_data = deck_to_animate[i] # Just read the data, don't pop it
		#var new_card = CardScene.instantiate()
		#add_child(new_card)
		#new_card.initialize(card_data.suit, card_data.rank)
		#
		## Add the new card to the "cards" group for easy cleanup later
		#new_card.add_to_group("cards")
		#
		## Start card off-screen
		#new_card.global_position = offscreen_deal_marker.global_position
		#new_card.z_index = i # Stack them correctly
		#
		## Calculate where it should go
		#var target_position = deck_position_marker.global_position + Vector2(0, i * -0.2)
		#
		#var tween = create_tween()
		#tween.set_trans(Tween.TRANS_CUBIC)
		#tween.set_ease(Tween.EASE_OUT)
		#tween.tween_property(new_card, "global_position", target_position, 0.2)
		#
		## Pause this function until the current card's animation is done
		#await tween.finished
		#
		## Optional small delay between cards
		## await get_tree().create_timer(0.02).timeout
	#
	#print("Deck animation finished!")

func shuffle_deck():
	for n in 8:
		deck.shuffle()
		print("deck shuffled %d time, " % n)
		print(deck)
#detect a mouse click
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:	
			var card = raycast_check_for_card()			
			if card:
				start_drag(card)
		else:
			if card_being_dragged:
				finish_drag()
			
func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(1, 1)

func finish_drag():
	card_being_dragged.scale = Vector2(1.05, 1.05)
	card_being_dragged = null
	
			
func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		print("hovered")
		highlight_card(card, true)
func on_hovered_off_card(card):
	if !card_being_dragged:
		print("hovered off")
		#is_hovering_on_card = false
		#check if we hovered off one card and straight on to another card:
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_on_card = false
		highlight_card(card, false)
	
	
func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1,1)
		card.z_index = 1
			
			
#THIS WONT WORK FOR CARD GAMES WITH HANDS>
func get_card_with_highest_z_index(cards):
	#Assume first card has highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	#loop through the rest to check for any higher Zs
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
	
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_card_with_highest_z_index(result)
	return null
	
	
#async func _animate_deck_creation():
	#for i in range(deck.size()):
		## ... (rest of the card creation logic is the same) ...
		#var card_data = deck.pop_front()
		#var new_card = CardScene.instantiate()
		#add_child(new_card)
		#new_card.initialize(card_data.suit, card_data.rank)
		#
		#new_card.global_position = deal_start_marker.global_position
		#new_card.z_index = i
		#var target_position = deck_pile_marker.global_position + Vector2(0, i * -0.2)
		#
		#var tween = create_tween()
		#tween.set_trans(Tween.TRANS_CUBIC)
		#tween.set_ease(Tween.EASE_OUT)
		#tween.tween_property(new_card, "global_position", target_position, 0.2)
		#
		## This is where we pause this function until the tween is done.
		#await tween.finished
