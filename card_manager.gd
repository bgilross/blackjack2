extends Node2D

# Preload our new scene at the top of the script.
const PLAYER_AREA_SCENE := preload("res://player_area.tscn")

# --- Add some layout constants to make tweaking easy ---
const PLAYER_POS := Vector2(540, 1650) # Bottom center
const DEALER_POS := Vector2(540, 270)  # Top center

const AI_ARC_CENTER := Vector2(540, 960) # Center of the screen
const AI_ARC_RADIUS := 700.0
# We'll place AIs in an arc from 215 degrees to 325 degrees
const AI_START_ANGLE_DEG := 215.0 
const AI_END_ANGLE_DEG := 325.0

# ...


#region Signals
# Signals announce key moments to other nodes (like the UIController).
signal round_over(results: Array)
signal player_busted(final_score: int)
signal dealer_busted(final_score: int)
signal winner_determined(winner_name: String, reason_text: String)
signal hand_score_updated(player_hand_score: int, dealer_hand_score: int)
signal total_score_updated(player_total: int, dealer_total: int)
#endregion

#region State Machine
enum GameState {
	MENU,
	SETUP,
	DEALING,
	CHECK_NATURALS,
	PLAYER_TURN,
	AI_TURN,
	DEALER_TURN,
	ROUND_OVER
}

var current_state: GameState = -1
#endregion

#region Constants and Properties
const SUITS := ["clubs", "diamonds", "hearts", "spades"]
const RANKS := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
const CARD_SCENE := preload("res://card.tscn")

var player_total_score: int = 0
var dealer_total_score: int = 0
#endregion


#region Node References
@onready var animation_controller: Node = $AnimationController
@onready var card_holder: Node2D = $CardHolder # Holds the visual deck
@onready var deck_position_marker: Marker2D = $DeckPileMarker
@onready var offscreen_deal_marker: Marker2D = $OffScreenStartMarker
@onready var ui_controller: Node = $UIController # Assuming you have this for buttons
#endregion

#region State Variables
var deck: Array[Dictionary] = []
var player_seats: Array[Dictionary] = []
var dealer_seat: Dictionary
var human_player_seat: Dictionary
#endregion


func _ready() -> void:
	print("ready running")
	print("current state: ")
	# Connect signals from the UIController (or buttons directly) to our handlers.
	# Assuming UIController has buttons and emits signals like "new_deal_pressed".
	# This keeps GameManager clean of direct button references.
	#ui_controller.new_deal_pressed.connect(_on_new_deal_pressed)
	ui_controller.hit_pressed.connect(_on_hit_pressed)
	ui_controller.stay_pressed.connect(_on_stay_pressed)

	# Connect our signals to the UIController's handlers
	self.winner_determined.connect(ui_controller._on_winner_determined)
	self.player_busted.connect(ui_controller._on_player_busted)
	self.hand_score_updated.connect(ui_controller._on_hand_score_updated)
	self.total_score_updated.connect(ui_controller._on_total_score_updated)
	
	set_state(GameState.MENU)
	emit_signal("total_score_updated", player_total_score, dealer_total_score)


# --- This should be connected to your "Start Game" button ---
func start_new_game(num_ai_players: int = 1):
	print("start new game running")
	# This is the entry point from your UI
	setup_players_and_table(num_ai_players)
	set_state(GameState.SETUP)

# --- The State Machine Core ---
func set_state(new_state: GameState, force_reentry: bool = false):
	if current_state == new_state and not force_reentry: return
	current_state = new_state
	print("Entering state: ", GameState.keys()[current_state])

	match new_state:
		GameState.MENU:
			await _enter_state_menu()

		GameState.SETUP:
			await _enter_state_setup()
			set_state(GameState.DEALING)

		GameState.DEALING:
			await _enter_state_dealing()
			set_state(GameState.CHECK_NATURALS)

		GameState.CHECK_NATURALS:
			await _enter_state_check_naturals()
			if not human_player_seat.has_natural and not human_player_seat.has_busted:
				set_state(GameState.PLAYER_TURN)
			else:
				set_state(GameState.AI_TURN)

		GameState.PLAYER_TURN:
			_enter_state_player_turn()
			# State will advance via button press handlers

		GameState.AI_TURN:
			await _enter_state_ai_turn()
			set_state(GameState.DEALER_TURN)

		GameState.DEALER_TURN:
			await _enter_state_dealer_turn()
			set_state(GameState.ROUND_OVER)

		GameState.ROUND_OVER:
			await _enter_state_round_over()
			set_state(GameState.MENU) # Or SETUP to auto-play another round

#region State Entry Functions
func _enter_state_menu():
	print("enter state menu running")
	# Your UIController would show the main menu here
	# For now, we start a game with 1 AI player automatically
	start_new_game(1)

func _enter_state_setup():
	_reset_round_data()
	create_deck_array()
	shuffle_deck_array()
	await create_deck_visuals()

func _enter_state_dealing():
	# Your UIController should disable Hit/Stay buttons here
	for _i in 2:
		for seat in player_seats:
			# Dealer's first card is face down
			var show_face = not (seat.is_dealer and seat.hand_parent.get_child_count() == 0)
			await deal_card(seat, show_face)
			await get_tree().create_timer(0.1).timeout # Small delay between each card
	update_all_hand_scores()

func _enter_state_check_naturals():
	for seat in player_seats:
		if _is_natural_blackjack(seat):
			seat.has_natural = true
	# Short delay to let players see the naturals
	await get_tree().create_timer(1.0).timeout

func _enter_state_player_turn():
	human_player_seat.instance.set_active_turn(true)
	# Your UIController should enable Hit/Stay buttons here

func _enter_state_ai_turn():
	human_player_seat.instance.set_active_turn(false)
	# Your UIController should disable Hit/Stay buttons here
	for seat in player_seats:
		if seat.is_human or seat.is_dealer or seat.has_natural or seat.has_busted:
			continue
		await _run_ai_logic(seat)

func _enter_state_dealer_turn():
	dealer_seat.instance.set_active_turn(true)
	if _are_any_players_still_in_game():
		await _reveal_dealer_hole_card()
		while dealer_seat.hand_score < 17:
			await deal_card(dealer_seat, true)
			update_all_hand_scores()
			await get_tree().create_timer(1.0).timeout
	else:
		# If everyone busted, just flip the card and end
		await _reveal_dealer_hole_card()
	dealer_seat.instance.set_active_turn(false)

func _enter_state_round_over():
	determine_winner()
	# Let results linger on screen for a few seconds
	await get_tree().create_timer(4.0).timeout
#endregion

#region Input Handlers (Connect these from your UI buttons)
func _on_hit_pressed():
	if current_state != GameState.PLAYER_TURN: return
	# Temporarily disable buttons to prevent spamming
	call_deferred("_player_hit_action")

func _on_stay_pressed():
	if current_state != GameState.PLAYER_TURN: return
	set_state(GameState.AI_TURN)

func _player_hit_action():
	await deal_card(human_player_seat, true)
	update_all_hand_scores()
	if human_player_seat.has_busted:
		set_state(GameState.AI_TURN)
	else:
		# Re-enable buttons if player hasn't busted
		pass # Your UIController would re-enable buttons here
#endregion

#region Core Logic
func _run_ai_logic(ai_seat: Dictionary):
	ai_seat.instance.set_active_turn(true)
	await get_tree().create_timer(1.0).timeout
	while ai_seat.hand_score < 17 and not ai_seat.has_busted:
		await deal_card(ai_seat, true)
		update_all_hand_scores()
		await get_tree().create_timer(1.0).timeout
	ai_seat.instance.set_active_turn(false)

func determine_winner():
	var results = []
	var dealer_score = dealer_seat.hand_score if not dealer_seat.has_busted else 0
	
	for seat in player_seats:
		if seat.is_dealer: continue
		var player_score = seat.hand_score if not seat.has_busted else 0
		var result_text = ""
		
		if seat.has_natural and not dealer_seat.has_natural:
			result_text = "Blackjack!"
		elif seat.has_busted:
			result_text = "Bust!"
		elif dealer_seat.has_busted:
			result_text = "Win!"
		elif player_score > dealer_score:
			result_text = "Win!"
		elif dealer_score > player_score:
			result_text = "Lose"
		else: # Push
			result_text = "Push"
		
		results.append({"name": seat.name, "result": result_text})
		print("%s: %s" % [seat.name, result_text])
		# Here you would tell the seat's instance to display this final result
		
	emit_signal("round_over", results)

func update_all_hand_scores():
	for seat in player_seats:
		seat.hand_score = calculate_hand_value(seat.hand_parent)
		seat.has_busted = seat.hand_score > 21
		seat.instance.update_display(seat.name, seat.hand_score, seat.has_busted)

func calculate_hand_value(hand_parent: Node2D) -> int:
	var total = 0
	var ace_count = 0
	for card in hand_parent.get_children():
		if card.is_face_up:
			total += card.get_value()
			if card.rank == "ace":
				ace_count += 1
	while total > 21 and ace_count > 0:
		total -= 10
		ace_count -= 1
	return total

func _are_any_players_still_in_game() -> bool:
	for seat in player_seats:
		if not seat.is_dealer and not seat.has_busted:
			return true
	return false

func _is_natural_blackjack(seat: Dictionary) -> bool:
	return seat.hand_parent.get_child_count() == 2 and calculate_hand_value(seat.hand_parent) == 21

#endregion

#region Setup & Teardown
func create_seat(name, is_human, is_dealer, pos, scale):
		var instance = PLAYER_AREA_SCENE.instantiate()
		add_child(instance)
		instance.position = pos
		instance.scale = scale
		instance.setup(name) # Call the new setup function
		return {"name": name, "is_human": is_human, "is_dealer": is_dealer,
				"instance": instance, "hand_parent": instance.get_hand_parent()}

func setup_players_and_table(num_ai_players: int):
	# Clear any old instances from a previous game first
	for seat in player_seats:
		if seat.has("instance") and is_instance_valid(seat.instance):
			seat.instance.queue_free()
	player_seats.clear()



	# 1. Human Player
	human_player_seat = create_seat("Player", true, false, PLAYER_POS, Vector2(1.1, 1.1))
	player_seats.append(human_player_seat)

	# 2. AI Players
	for i in range(num_ai_players):
		var fraction = 0.5 if num_ai_players <= 1 else float(i) / (num_ai_players - 1)
		var angle_rad = deg_to_rad(lerp(AI_START_ANGLE_DEG, AI_END_ANGLE_DEG, fraction))
		var pos = AI_ARC_CENTER + Vector2(cos(angle_rad), sin(angle_rad)) * AI_ARC_RADIUS
		var ai_seat = create_seat("AI " + str(i + 1), false, false, pos, Vector2(0.85, 0.85))
		player_seats.append(ai_seat)
		
	# 3. Dealer
	dealer_seat = create_seat("Dealer", false, true, DEALER_POS, Vector2(1.0, 1.0))
	player_seats.append(dealer_seat)

func _reset_round_data():
	# This function is now much simpler.
	for seat in player_seats:
		seat.hand_score = 0
		seat.has_natural = false
		seat.has_busted = false
		# The visual reset is now handled by the update_all_hand_scores call
		for card in seat.hand_parent.get_children():
			card.queue_free()
	for card in card_holder.get_children():
		card.queue_free()
#endregion

#region Deck & Card Management
func deal_card(seat: Dictionary, should_be_face_up: bool):
	if card_holder.get_child_count() == 0: return
	var top_card: Node2D = card_holder.get_child(0)
	top_card.reparent(seat.hand_parent)
	var move_tween = animation_controller.animate_deal_to_hand(top_card, seat.hand_parent)
	if should_be_face_up and not top_card.is_face_up:
		await get_tree().create_timer(move_tween.get_total_elapsed_time() * 0.4).timeout
		await animation_controller.animate_flip(top_card)
	await move_tween.finished

func create_deck_visuals():
	var last_tween: Tween
	for i in range(deck.size()):
		var new_card: Node2D = CARD_SCENE.instantiate()
		card_holder.add_child(new_card)
		new_card.initialize(deck[i].suit, deck[i].rank)
		new_card.global_position = offscreen_deal_marker.global_position
		new_card.z_index = i
		last_tween = animation_controller.animate_stack_in_deck(new_card, deck_position_marker, i)
	if last_tween:
		await last_tween.finished

func create_deck_array():
	deck.clear()
	for suit in SUITS:
		for rank in RANKS:
			deck.append({"suit": suit, "rank": rank})

func shuffle_deck_array():
	deck.shuffle()

func _reveal_dealer_hole_card():
	var hole_card = dealer_seat.hand_parent.get_child(0)
	if not hole_card.is_face_up:
		await animation_controller.animate_flip(hole_card)
		update_all_hand_scores()
		await get_tree().create_timer(0.5).timeout
#endregion
