extends Node2D

#region Signals
# Signals announce key moments to other nodes (like the UIController).
signal player_busted(final_score: int)
signal dealer_busted(final_score: int)
signal winner_determined(winner_name: String, reason_text: String)
signal hand_score_updated(player_hand_score: int, dealer_hand_score: int)
signal total_score_updated(player_total: int, dealer_total: int)
#endregion

#region State Machine
enum GameState {
	READY,
	SETUP,
	DEALING,
	CHECK_NATURALS,  
	PLAYER_TURN,
	AI_TURN,   
	DEALER_TURN,
	ROUND_OVER
}

var current_state: GameState
#endregion

#region Constants and Properties
const SUITS := ["clubs", "diamonds", "hearts", "spades"]
const RANKS := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
const CARD_SCENE := preload("res://card.tscn")

var deck: Array[Dictionary] = [] # The logical data for the deck
var player_total_score: int = 0
var dealer_total_score: int = 0
#endregion

#region Node References (OnReady)
@onready var animation_controller: Node = $AnimationController
@onready var ui_controller: Node = $UIController # Get a reference to the UI controller
@onready var card_holder: Node2D = $CardHolder
@onready var player_hand_parent: Node2D = $PlayerHand
@onready var dealer_hand_parent: Node2D = $DealerHand
@onready var deck_position_marker: Marker2D = $DeckPileMarker
@onready var offscreen_deal_marker: Marker2D = $OffScreenStartMarker
#endregion


func _ready() -> void:
	# Connect signals from the UIController (or buttons directly) to our handlers.
	# Assuming UIController has buttons and emits signals like "new_deal_pressed".
	# This keeps GameManager clean of direct button references.
	ui_controller.new_deal_pressed.connect(_on_new_deal_pressed)
	ui_controller.hit_pressed.connect(_on_hit_pressed)
	ui_controller.stay_pressed.connect(_on_stay_pressed)

	# Connect our signals to the UIController's handlers
	self.winner_determined.connect(ui_controller._on_winner_determined)
	self.player_busted.connect(ui_controller._on_player_busted)
	self.hand_score_updated.connect(ui_controller._on_hand_score_updated)
	self.total_score_updated.connect(ui_controller._on_total_score_updated)
	
	set_state(GameState.READY)
	emit_signal("total_score_updated", player_total_score, dealer_total_score)


# --- The Heart of the State Machine ---
func set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	# We can have an exit state logic block here if needed in the future
	# match current_state:
	#	  GameState.PLAYER_TURN: print("Leaving player turn")

	current_state = new_state
	print("Entering state: ", GameState.keys()[current_state])
	
	# The state machine now DRIVES the game loop by calling async functions.
	# The `await` keyword ensures we don't move to the next logical state
	# until the current state's process (like dealing cards) is complete.
	match new_state:
		GameState.READY:
			await _enter_state_ready()
		
		GameState.SETUP:
			await _enter_state_setup()
			# After setup is complete, automatically transition to dealing
			set_state(GameState.DEALING)

		GameState.DEALING:
			await _enter_state_dealing()
			# After dealing, check game state and decide next turn
			var player_hand_score = calculate_hand_value(player_hand_parent)
			if player_hand_score == 21:
				print("natural black jack, checking for dealer blackjack")
				set_state(GameState.DEALER_TURN) # Blackjack! Skip player turn.
			else:
				set_state(GameState.PLAYER_TURN)

		GameState.PLAYER_TURN:
			_enter_state_player_turn()

		GameState.DEALER_TURN:
			await _enter_state_dealer_turn()
			# After dealer's turn, the round is over
			set_state(GameState.ROUND_OVER)

		GameState.ROUND_OVER:
			await _enter_state_round_over()
			# The game now waits here for player input to start a new round.
			# The READY state will handle this.
			set_state(GameState.READY)


# --- State-Specific Logic Functions ---

func _enter_state_ready():
	ui_controller.show_ready_ui()

func _enter_state_setup():
	ui_controller.show_gameplay_ui(false) # Disable buttons during setup
	await clear_table()
	create_deck_array() 
	shuffle_deck_array()
	await create_deck_visuals()

func _enter_state_dealing():
	# Deal 2 cards to player and dealer alternately
	await deal_card(player_hand_parent, true)
	await deal_card(dealer_hand_parent, false) # Dealer's first card is face down
	await deal_card(player_hand_parent, true)
	await deal_card(dealer_hand_parent, true)
	update_hand_scores()

func _enter_state_player_turn():
	ui_controller.show_gameplay_ui(true) # Enable Hit/Stay buttons

func _enter_state_dealer_turn():
	ui_controller.show_gameplay_ui(false) # Disable buttons during dealer's turn
	
	# Reveal hole card
	var hole_card = dealer_hand_parent.get_child(0)
	if not hole_card.is_face_up:
		var flip_tween = animation_controller.animate_flip(hole_card)
		await flip_tween.finished
		update_hand_scores()
		await get_tree().create_timer(0.5).timeout # Dramatic pause

	# Dealer hits until 17 or more
	var dealer_score = calculate_hand_value(dealer_hand_parent)
	while dealer_score < 17:
		print("Dealer score is %d. Hitting..." % dealer_score)
		await get_tree().create_timer(1.0).timeout 
		await deal_card(dealer_hand_parent, true)
		dealer_score = calculate_hand_value(dealer_hand_parent)
		update_hand_scores()

func _enter_state_round_over():
	determine_winner()
	emit_signal("total_score_updated", player_total_score, dealer_total_score)
	await get_tree().create_timer(2.0).timeout # Pause to show results

# --- Button Press Handlers ---

func _on_new_deal_pressed():
	if current_state == GameState.READY:
		set_state(GameState.SETUP)

func _on_hit_pressed():
	if current_state == GameState.PLAYER_TURN:
		# Temporarily disable buttons to prevent spamming
		ui_controller.show_gameplay_ui(false)
		
		# Use call_deferred to avoid race conditions with the state machine
		call_deferred("_player_hit_action")

func _player_hit_action():
	print("player hit action running")
	await deal_card(player_hand_parent, true)
	update_hand_scores()
	var player_hand_score = calculate_hand_value(player_hand_parent)
	if player_hand_score > 21:
		emit_signal("player_busted", player_hand_score)
		set_state(GameState.DEALER_TURN)
	else:
		print("else running")
		ui_controller.show_gameplay_ui(true)
		# Re-enable buttons if player hasn't busted
		set_state(GameState.PLAYER_TURN)

func _on_stay_pressed():
	if current_state == GameState.PLAYER_TURN:
		set_state(GameState.DEALER_TURN)

# --- Core Game Logic Functions ---

func determine_winner():
	var player_hand_val = calculate_hand_value(player_hand_parent)
	var dealer_hand_val = calculate_hand_value(dealer_hand_parent)
	
	if player_hand_val > 21:
		# This case is already handled by player_busted signal, but good for scoring
		dealer_total_score += 1
		# The winner signal is still useful for a final "Dealer Wins" banner
		emit_signal("winner_determined", "Dealer", "Player Busts!")
	elif dealer_hand_val > 21:
		player_total_score += 1
		emit_signal("dealer_busted", dealer_hand_val)
		emit_signal("winner_determined", "Player", "Dealer Busts!")
	elif player_hand_val > dealer_hand_val:
		player_total_score += 1
		emit_signal("winner_determined", "Player", "Higher Score!")
	elif dealer_hand_val > player_hand_val:
		dealer_total_score += 1
		emit_signal("winner_determined", "Dealer", "Higher Score!")
	else:
		emit_signal("winner_determined", "Push", "It's a Tie!")

func update_hand_scores():
	var player_hand_val = calculate_hand_value(player_hand_parent)
	var dealer_hand_val = calculate_hand_value(dealer_hand_parent)
	emit_signal("hand_score_updated", player_hand_val, dealer_hand_val)

func calculate_hand_value(hand_parent: Node2D) -> int:
	var total_value = 0
	var ace_count = 0
	for card in hand_parent.get_children():
		# IMPORTANT: Only count face-up cards for the score
		if card.is_face_up:
			total_value += card.get_value() # Using new decoupled get_value() method
			if card.rank == "ace":
				ace_count += 1
	
	while total_value > 21 and ace_count > 0:
		total_value -= 10
		ace_count -= 1
	return total_value

# --- Deck and Card Management ---

func deal_card(hand_parent: Node2D, should_be_face_up: bool):
	if card_holder.get_child_count() == 0:
		print("Deck empty")
		return
	
	var top_card: Node2D = card_holder.get_child(0)
	top_card.reparent(hand_parent)
	
	var move_tween = animation_controller.animate_deal_to_hand(top_card, hand_parent)
	
	if should_be_face_up and not top_card.is_face_up:
		# Wait for the card to be halfway through its move before flipping
		await get_tree().create_timer(move_tween.get_total_elapsed_time() / 2.0).timeout
		var flip_tween = animation_controller.animate_flip(top_card)
		await flip_tween.finished
		
	await move_tween.finished

func clear_table():
	# Here you could have an animation of cards flying off-screen
	for card in player_hand_parent.get_children(): card.queue_free()
	for card in dealer_hand_parent.get_children(): card.queue_free()
	for card in card_holder.get_children(): card.queue_free()
	update_hand_scores() # Reset scores to 0
	await get_tree().create_timer(0.1).timeout # Small delay to ensure nodes are freed

func create_deck_array():
	deck.clear()
	for suit in SUITS:
		for rank in RANKS:
			deck.append({"suit": suit, "rank": rank})

func shuffle_deck_array():
	deck.shuffle()
	
func create_deck_visuals():
	var tweens = []
	for i in range(deck.size()):
		var new_card: Node2D = CARD_SCENE.instantiate()
		card_holder.add_child(new_card)
		new_card.initialize(deck[i].suit, deck[i].rank)
		new_card.global_position = offscreen_deal_marker.global_position
		new_card.z_index = i
		
		var tween = animation_controller.animate_stack_in_deck(new_card, deck_position_marker, i)
		tweens.append(tween)
	
	# Wait for the last tween in the sequence to finish
	if not tweens.is_empty():
		await tweens.back().finished
