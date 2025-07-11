extends Control

signal player_turn_finished

enum GameState {
	MENU,
	SETUP,
	PLAYER_TURN,
	AI_TURN,
	DEALER_TURN,
	ROUND_OVER,
}

const AI_SEATS = {
	"AI1": 0, "AI2": 1, "AI3": 2, "AI4": 4, "AI5": 5, "AI6": 6
	}

var current_state: GameState = -1

const CARD_SCENE := preload("res://card.tscn")
const PLAYER_AREA_SCENE := preload("res://player_area.tscn")

const TOTAL_AI_SEATS: int = 6
const HUMAN_SEAT_INDEX: int = 3
const DEALER_SEAT_INDEX: int = 7 #or -1?
const DELAY_TIME: int = .6

var deck: Array = []
var current_turn_index: int = -1
var players: Array = []
@onready var ui_manager = $UIManager
@onready var table = $Table

func clear_all():
	deck = []
	players = []
	table.clear_all()
	
func _ready() -> void:	
	ui_manager.start_button_pressed.connect(_on_start_game)
	table.table_setup_complete.connect(_on_table_setup_complete)
	ui_manager.deal_button_pressed.connect(_on_deal)
	ui_manager.hit_button_pressed.connect(_on_hit)
	ui_manager.stand_button_pressed.connect(_on_stand)
	#

func find_player(player_name: String = "Player"):
	for player in players:
		if player.name == player_name:
			print("found player: ", player)
			return player
		
func _on_hit():
	var player = find_player()	
	await deal_card(player, true)
	if player.hand_value > 21:
		player.is_busted = true
		table.get_seat(player.seat_index).update_hand_value(player.hand_value, true)
		ui_manager.enter_non_player_turn() # Hide Hit/Stand buttons

		# --- NEW LINE ---
		# Tell the table to perform the visual action for the player
		await table.reveal_hand(player.seat_index)
		# --- END NEW LINE ---
		player_turn_finished.emit()
	
func pause():
	await get_tree().create_timer(DELAY_TIME).timeout

func _on_stand():
	ui_manager.enter_non_player_turn() # Hide Hit/Stand buttons
	player_turn_finished.emit() # End the turn
	
func _on_deal():
	await _deal_hands()
	enter_turn_phase()

func enter_turn_phase():
	print("entering turn phase.")
	ui_manager.enter_non_player_turn()
	for player in players:
		table.set_active_turn(player.seat_index, true)
		print("in player for loop, current player is: ", player)
		await resolve_turn(player)
		table.set_active_turn(player.seat_index, false)
	#technically any player/AI blackjacks should be resolved immediately here, as well as maybe dealer blackjack check if none have it? but I'm going to wait for now.
	#find the first players/AIs turn and start it up
	enter_round_over()

func enter_round_over():
	for player in players:
		update_player_display(player)
		if !player.is_busted:			
			table.reveal_hand(player.seat_index)
			var new_score = player.score + 1
			player.score = new_score
		update_player_display(player)
	ui_manager.enter_round_over()

func resolve_turn(player: PlayerData):
	if player.name == "Dealer":
		await enter_dealer_turn(player)
	elif player.is_ai:
		await enter_ai_turn(player)
	elif player.name == "Player":
		await enter_player_turn(player)
	else: print("error no player turn to go to? or something?")
	
func enter_player_turn(player: PlayerData):
	ui_manager.enter_player_turn()
	await self.player_turn_finished
		
func enter_ai_turn(player: PlayerData):
	await ai_turn_logic(player)	

func ai_turn_logic(player: PlayerData):
		while player.hand_value < 17 and !player.is_busted:
			await deal_card(player, true)
			if player.hand_value > 21:
				#player busts.....
				player.is_busted = true
				await table.reveal_hand(player.seat_index)
				update_player_display(player)
				#turn is over so return?
				await pause()
				return
			await pause()
			
func enter_dealer_turn(player: PlayerData):
	await ai_turn_logic(player)
	
func _deal_hands():
	#clear previous hand value scores and hand arrays...
	for player in players:
		player.reset_for_new_round()
		update_player_display(player)
	print("dealing for # (players.size())", players.size())
	print("dealing in this order: ", players)
	for player in players:
		if player.name == "Player":
			await deal_card(player, true)
		else:
			await deal_card(player)
	for player in players:
		await deal_card(player, true)
	
func deal_card(player: PlayerData, flip_face_up: bool = false):
	if deck.is_empty(): return
	var card_data = deck.pop_front()
	card_data.face_up = flip_face_up
	player.hand.append(card_data)
	player.hand_value = calculate_hand_value(player)	
	await table.animate_deal_card(player.seat_index, card_data, flip_face_up)
	#calculating the visible card score only here, simply to keep Hand Scores updated
	if flip_face_up:
		var visible_hand_value = calculate_hand_value(player, flip_face_up)
		player.visible_hand_value = visible_hand_value
		update_player_display(player, true)
	var hand_value = calculate_hand_value(player)
	player.hand_value = hand_value

func update_player_display(player: PlayerData, visible_only: bool = false):
	var target_seat = table.get_seat(player.seat_index)
	if target_seat:
		if !visible_only:
			target_seat.update_display(player.score, player.hand_value, player.is_busted)
		elif visible_only:
			target_seat.update_display(player.score, player.visible_hand_value, player.is_busted)

func _on_table_setup_complete():
	#tell the UI to get allow the deal button/ whatever will start round to be allowed.
	ui_manager.enter_round_start()
	#waiting for deal button to be pressed for now	

func _on_start_game(ai_players: int):	
	ui_manager.enter_setup()
	clear_all()
	_create_player_list(ai_players)
	table.setup_table(players)
	create_deck()
	shuffle_deck()
	
func calculate_hand_value(player: PlayerData, visible_only: bool = false) -> int:
	var total = 0
	var ace_count = 0
	for card in player.hand:	
		if visible_only and !card.face_up: continue
		total += card.value
		if card.rank == "Ace":
			ace_count += 1
	while total > 21 and ace_count > 0:
		total -= 10
		ace_count -= 1
	return total
	
func create_deck():
	deck.clear()
	var suits = ["Hearts", "Diamonds", "Clubs", "Spades"]
	var ranks = {
		"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, 
		"8": 8, "9": 9, "10": 10, "Jack": 10, "Queen": 10, "King": 10, "Ace": 11
	}
	for s in suits:
		for r in ranks.keys():
			deck.append(CardData.new(s, r, ranks[r]))

func shuffle_deck():
	deck.shuffle()

func _create_player_list(num_ai_to_select: int):
	players.clear()
	var selected_ai_indices = _select_ai_seats(num_ai_to_select)
	players.append(PlayerData.new("Player", HUMAN_SEAT_INDEX, false))
	players.append(PlayerData.new("Dealer", DEALER_SEAT_INDEX, true))
	for i in range(selected_ai_indices.size()):
		var seat_idx = selected_ai_indices[i]		
		# Find the AI's "official" name by looking up its seat index.
		var ai_name = "AI ?"
		for key in AI_SEATS:
			if AI_SEATS[key] == seat_idx:
				ai_name = key
				break
		players.append(PlayerData.new(ai_name, seat_idx, true))
	players.sort_custom(func(a, b): return a.seat_index < b.seat_index)
	print("Active players for this round (in table order):")
	for p in players:
		print(p.name, " at Seat", p.seat_index)
	print("players looks like: ", players)

func _select_ai_seats(num_ai_to_select: int) -> Array[int]:
	var selected_indices: Array[int] = []

	match num_ai_to_select:
		0:			# No AI players, return an empty array.
			pass
		1:
			# Rule: If 1 AI, pick randomly between AI 2 or AI 5.
			# These are good "anchor" positions.
			var choices = [AI_SEATS["AI2"], AI_SEATS["AI5"]]
			selected_indices.append(choices.pick_random())
		2:
			# Rule: If 2 AI, it must be AI 2 and AI 5.
			selected_indices = [AI_SEATS["AI2"], AI_SEATS["AI5"]]
		3:
			# Rule: Either (AI 2 + one of 4/5/6) OR (AI 5 + one of 2/3/4)
			# Let's simplify this to one balanced choice for consistency.
			# A very balanced set of 3 is AI 2, AI 5, and one of the far ends.
			# Let's deterministically pick AI 2, AI 5, and AI 4.
			selected_indices = [AI_SEATS["AI2"], AI_SEATS["AI4"], AI_SEATS["AI6"]]
			# If you want randomness:
			# var side_choices = [AI_SEATS["AI3"], AI_SEATS["AI4"], AI_SEATS["AI6"]]
			# selected_indices = [AI_SEATS["AI2"], AI_SEATS["AI5"], side_choices.pick_random()]
		4:
			# Rule: If 4 AI, it must be AI 1, 3, 4, and 6.
			selected_indices = [AI_SEATS["AI1"], AI_SEATS["AI3"], AI_SEATS["AI4"], AI_SEATS["AI6"]]
		5:
			# For 5 or 6, we can fall back to random selection from all available spots.
			# Let's pick 5 balanced seats.
			selected_indices = [AI_SEATS["AI1"], AI_SEATS["AI2"], AI_SEATS["AI4"], AI_SEATS["AI5"], AI_SEATS["AI6"]]
		6:
			# All AIs are selected.
			selected_indices = [AI_SEATS["AI1"], AI_SEATS["AI2"], AI_SEATS["AI3"], AI_SEATS["AI4"], AI_SEATS["AI5"], AI_SEATS["AI6"]]
		_:
			# Default case for any unexpected number.
			print_debug("Warning: Unexpected number of AI players requested.")
			
	print("Rule-based selection for",  num_ai_to_select, " AIs resulted in seats:",  selected_indices)
	return selected_indices	
	
#func _create_player_list(num_ai_to_select: int):
	#players.clear()
	## A. Always add the human player.
	#players.append({
		#"name": "Player",
		#"seat_index": HUMAN_SEAT_INDEX,
		#"hand": [],
		#"score": 0,
		#"is_ai": false
	#})
	## B. Always add the dealer.
	#players.append({
		#"name": "Dealer",
		#"seat_index": DEALER_SEAT_INDEX,
		#"hand": [],
		#"score": 0,
		#"is_ai": true # The dealer is a type of AI
	#})	
	#var selected_ai_indices = _select_ai_seats(num_ai_to_select)
#
	#for i in range(selected_ai_indices.size()):
		#var seat_idx = selected_ai_indices[i]		
		## Find the AI's "official" name by looking up its seat index.
		#var ai_name = "AI ?"
		#for key in AI_SEATS:
			#if AI_SEATS[key] == seat_idx:
				#ai_name = key
				#break
#
		#players.append({
			#"name": ai_name,
			#"seat_index": seat_idx,
			#"hand": [],
			#"score": 0,
			#"is_ai": true
		#})
	#players.sort_custom(func(a, b): return a.seat_index < b.seat_index)
	#
	#print("Active players for this round (in table order):")
	#for p in players:
		#print(p.name, " at Seat", p.seat_index)
	#print("players looks like: ", players)
	#
#func deal_hands(players: int):pass
#

#func calculate_player_score(player_hand) -> int:
	#var score = 0
	#var ace_count = 0
	#for card_data in player_hand:
		#score += card_data.value
		#if card_data.rank == "Ace":
			#ace_count += 1
	#
	## Devalue Aces from 11 to 1 if the score is over 21
	#while score > 21 and ace_count > 0:
		#score -= 10
		#ace_count -= 1
		#
	#return score
#
#func reset_data():	
	#dealer_hand.score = 0
	#dealer_hand.hand.clear()
#
	#
