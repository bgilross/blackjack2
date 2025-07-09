extends Node2D

signal player_busted(final_score)
signal dealer_busted(final_score)
signal winner_determined(winner_name, reason_text) # e.g., ("Player", "Blackjack!")
signal score_updated(player_score, dealer_score)

enum GameState {
	READY,
	DEALING,
	PLAYER_TURN,
	DEALER_TURN,
	ROUND_OVER
}

var current_state: GameState

const SUITS = ["clubs", "diamonds", "hearts", "spades"]
const RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
var deck: Array = []
var current_players = 2 #DEALER counts as a player.
var game_over: bool = false
const CardScene = preload("res://card.tscn")
const COLLISION_MASK_CARD = 1

var player_hand_score
var dealer_hand_score
var player_score: int = 0
var dealer_score: int = 0

@onready var screen_size = get_viewport_rect().size
@onready var deck_position_marker: Marker2D = $DeckPileMarker
@onready var offscreen_deal_marker: Marker2D = $OffScreenStartMarker
@onready var new_deal_button: Button = $UI/Menu/NewDeal_button
@onready var deal_button: Button = $UI/Menu/Deal_button
@onready var hit_button: Button = $UI/Menu/Hit_button
@onready var stay_button: Button = $UI/Menu/Stay_button
@onready var card_holder: Node2D = $CardHolder
@onready var player_hand_parent: Node2D = $PlayerHand
@onready var dealer_hand_parent: Node2D = $DealerHand
@onready var player_score_label: Label = $UI/PlayerScoreLabel
@onready var dealer_score_label: Label = $UI/DealerScoreLabel
@onready var player_hand_score_label: Label = $UI/PlayerHandScoreLabel
@onready var dealer_hand_score_label: Label = $UI/DealerHandScoreLabel
@onready var animation_controller = $AnimationController # Get a reference

func _ready() -> void:
	new_deal_button.pressed.connect(setup_deck)	
	deal_button.pressed.connect(_on_NewDeal_pressed)
	hit_button.pressed.connect(_on_Hit_pressed)
	stay_button.pressed.connect(_on_Stay_pressed)
	
	set_state(GameState.READY)	
	update_scoreboard()
	position_score_labels()

func set_state(new_state: GameState):
	if current_state == new_state:
		return
	
	print("Changing state from ", GameState.keys()[current_state], " to ", GameState.keys()[new_state])
	current_state = new_state

	# 3. Manage all UI and logic from one place
	match new_state:
		GameState.READY:
			new_deal_button.disabled = false
			deal_button.disabled = true
			hit_button.disabled = true
			stay_button.disabled = true
			# Maybe show a "Press New Deal" message
		
		GameState.DEALING:
			new_deal_button.disabled = true
			deal_button.disabled = true
			hit_button.disabled = true
			stay_button.disabled = true
			# The deal_hands function will run and then change state
			deal_hands() 

		GameState.PLAYER_TURN:
			hit_button.disabled = false
			stay_button.disabled = false
			# Check for blackjack immediately
			if player_hand_score == 21:
				set_state(GameState.DEALER_TURN)

		GameState.DEALER_TURN:
			hit_button.disabled = true
			stay_button.disabled = true
			play_dealer_turn() # This function will run and then change state

		GameState.ROUND_OVER:
			new_deal_button.disabled = false
			deal_button.disabled = false # Or maybe not, depending on your flow
			hit_button.disabled = true
			stay_button.disabled = true
			# Show a "Winner!" or "Bust!" banner

func _on_NewDeal_pressed():
	if current_state == GameState.READY or current_state == GameState.ROUND_OVER:
		setup_deck() # This function would now transition state to DEALING at the end

func _on_Hit_pressed():
	if current_state == GameState.PLAYER_TURN:
		player_hit()
		
func _on_Stay_pressed():
	if current_state == GameState.PLAYER_TURN:
		set_state(GameState.DEALER_TURN)

func update_scoreboard():
	player_score_label.text = "Player: " + str(player_score)
	dealer_score_label.text = "Dealer: " + str(dealer_score)

func play_dealer_turn():
	if player_hand_score != 21:
		#flip hole card and calculate score.
		var hole_card = dealer_hand_parent.get_child(0)
		if not hole_card.is_face_up:
			var flip_tween = animation_controller.animate_flip(hole_card)
			await flip_tween.finished
			update_scores() # Update the score display now that the card is visible
		# Add a small delay for dramatic effect
		await get_tree().create_timer(0.5).timeout
	# 2. Loop: Dealer must hit if score is 16 or less
		var dealer_score = calculate_hand_value(dealer_hand_parent)
		if dealer_hand_score < player_hand_score && player_hand_score < 21:
			while dealer_score < 17:
				print("Dealer score is %d. Hitting..." % dealer_score)
				await get_tree().create_timer(1.0).timeout # Pause so it's not instant
				
				await deal_card(dealer_hand_parent, true)
				update_scores()
				dealer_score = calculate_hand_value(dealer_hand_parent) # Recalculate score for the loop condition
	
	# 3. The dealer's turn is over. Determine the winner.
	print("Dealer stands with %d." % dealer_score)
	await get_tree().create_timer(0.5).timeout
	determine_winner()
	set_state(GameState.ROUND_OVER)

func determine_winner():
	var player_hand = calculate_hand_value(player_hand_parent)
	var dealer_hand = calculate_hand_value(dealer_hand_parent)	
	print("Final Scores -> Player: %d, Dealer: %d" % [player_score, dealer_score])	
	if player_hand > 21:
		dealer_score = dealer_score + 1
		print("Result: Player busts! Dealer wins.")
	elif dealer_hand > 21:
		player_score = player_score + 1
		print("Result: Dealer busts! Player wins.")
	elif player_hand > dealer_hand:
		player_score = player_score + 1
		print("Result: Player wins!")
	elif dealer_hand > player_hand:
		dealer_score = dealer_score + 1
		print("Result: Dealer wins.")
	else:
		print("Result: It's a push (tie).")	
	# Re-enable the new deal button for the next round
	update_scoreboard()
	new_deal_button.disabled = false

func player_hit():
	await deal_card(player_hand_parent, true)
	update_scores()	
	if player_hand_score > 21:
		set_state(GameState.DEALER_TURN)
	
func update_scores(hand = null):
	print("updateing scores")
	player_hand_score = calculate_hand_value(player_hand_parent)
	player_hand_score_label.text = "Player: " + str(player_hand_score)
	
	dealer_hand_score = calculate_hand_value(dealer_hand_parent)
	dealer_hand_score_label.text = "Dealer: " + str(dealer_hand_score)	

func position_score_labels():
	player_hand_score_label.position = Vector2(player_hand_parent.position.x, player_hand_parent.position.y - 185)
	dealer_hand_score_label.position = Vector2(dealer_hand_parent.position.x, dealer_hand_parent.position.y + 160)

func calculate_hand_value(hand_parent: Node2D) -> int:
	var total_value = 0
	var ace_count = 0

	for card in hand_parent.get_children():
		if card.is_face_up:
			total_value += card.value
			if card.is_ace():
				ace_count += 1
	while total_value > 21 and ace_count > 0:
		total_value -= 10
		ace_count -= 1
	return total_value

func clear_round():
	for card in player_hand_parent.get_children(): card.queue_free()
	for card in dealer_hand_parent.get_children(): card.queue_free()
	player_hand_score = 0
	dealer_hand_score = 0
	player_hand_score_label.text = "Player: " + str(player_hand_score)
	dealer_hand_score_label.text = "Dealer: " + str(dealer_hand_score)	

func deal_hands():	
	await clear_round()	
	deal_button.disabled = true
	var players_turn = true
	for i in current_players * 2:		
		if card_holder.get_child_count() == 0:
			print("Deck is empty")
			break
		
		if players_turn:
			await deal_card(player_hand_parent, true)
		else:
			var is_first_card = (dealer_hand_parent.get_child_count() == 0)
			var show_face = not is_first_card
			await deal_card(dealer_hand_parent, show_face)			
		players_turn = !players_turn
	update_scores()
	if player_hand_score != 21:
		hit_button.disabled = false
		stay_button.disabled = false
	else:
		play_dealer_turn()
	
func deal_card(hand_parent: Node2D, should_be_face_up: bool):
	if card_holder.get_child_count() == 0:
		print("Deck empty")
		return		
	var top_card: Node2D = card_holder.get_child(0)
	top_card.reparent(hand_parent)	
	var move_tween = animation_controller.animate_deal_to_hand(top_card, hand_parent)	
	if should_be_face_up and not top_card.is_face_up:
		var flip_tween = animation_controller.animate_flip(top_card)
		await flip_tween.finished  
	await move_tween.finished
	
func setup_deck():
	new_deal_button.disabled = true
	deal_button.disabled = true
	# Clear any existing cards
	for card in card_holder.get_children(): card.queue_free()
	for card in player_hand_parent.get_children(): card.queue_free()
	for card in dealer_hand_parent.get_children(): card.queue_free()
	
	create_deck_array() 
	shuffle_deck_array()
	await create_deck_visuals()	
	deal_button.disabled = false
		
func create_deck_visuals() -> void:
	print("Creating deck visuals...")
	var last_tween: Tween = null	
	for i in range(deck.size()):
		var new_card = CardScene.instantiate()
		card_holder.add_child(new_card)
		new_card.initialize(deck[i].suit, deck[i].rank)		
		new_card.global_position = offscreen_deal_marker.global_position
		new_card.z_index = i	
		var current_tween = animation_controller.animate_stack_in_deck(new_card, deck_position_marker, i)		
		if i == deck.size() - 1:
			last_tween = current_tween	
	if last_tween:
		await last_tween.finished

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
		
func _process(delta: float) -> void:
	pass
