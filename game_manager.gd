extends Control

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

var deck: Array = []
var dealer_hand: Dictionary = {"hand": [], "score": 0}
var current_turn_index: int = -1
var players: Array = []
@onready var ui_manager = $UIManager
@onready var table = $Table

func _ready() -> void:	
	ui_manager.start_button_pressed.connect(_on_start_game)
	ui_manager.deal_button_pressed.connect(_on_deal)
	ui_manager.hit_button_pressed.connect(_on_hit)
	ui_manager.stand_button_pressed.connect(_on_stand)
	table.table_setup_complete.connect(_on_table_setup_complete)
	table.hide_table()
	
func _on_start_game(ai_players: int):	
	ui_manager.hide_start_menu()
	_create_player_list(ai_players)
	#_build_current_turn_order()
	table.setup_table(players)
	create_deck()
	shuffle_deck()
	print("deck card 1", deck[0])

func _on_deal():
	_deal_hands()

func _deal_hands():
	print("dealing for # (players.size())", players.size())
	print("dealing in this order: ", players)
	for player in players:
		if player.name == "Player":
			await deal_card(player, true)
		else:
			await deal_card(player)
	for player in players:
		await deal_card(player, true)
		

func deal_card(player, flip_face_up: bool = false):
	if deck.is_empty(): return
	var card_data = deck.pop_front()
	player.hand.append(card_data)
	print("dealing: ", card_data, "to ", player)
	await table.animate_deal_card(player.seat_index, card_data, flip_face_up)
	player.score = calculate_player_score(player.hand)
	#update score somehow??
	# We need a way to get the area and update its display.
	#var target_area = table.get_area_for_seat(player_data.seat_index)
	# The PlayerArea script should probably just have one update function
	# target_area.update_display(player_data.score, false)

func _on_hit():
	pass
	
func _on_stand():
	pass

func _on_table_setup_complete():
	#tell the UI to get allow the deal button/ whatever will start round to be allowed.
	ui_manager.enter_round_start()
	
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
			selected_indices = AI_SEATS.values()
		_:
			# Default case for any unexpected number.
			print_debug("Warning: Unexpected number of AI players requested.")
			
	print("Rule-based selection for",  num_ai_to_select, " AIs resulted in seats:",  selected_indices)
	return selected_indices	
	
func _create_player_list(num_ai_to_select: int):
	players.clear()
	# A. Always add the human player.
	players.append({
		"name": "Player",
		"seat_index": HUMAN_SEAT_INDEX,
		"hand": [],
		"score": 0,
		"is_ai": false
	})
	# B. Always add the dealer.
	players.append({
		"name": "Dealer",
		"seat_index": DEALER_SEAT_INDEX,
		"hand": [],
		"score": 0,
		"is_ai": true # The dealer is a type of AI
	})	
	var selected_ai_indices = _select_ai_seats(num_ai_to_select)

	for i in range(selected_ai_indices.size()):
		var seat_idx = selected_ai_indices[i]		
		# Find the AI's "official" name by looking up its seat index.
		var ai_name = "AI ?"
		for key in AI_SEATS:
			if AI_SEATS[key] == seat_idx:
				ai_name = key
				break

		players.append({
			"name": ai_name,
			"seat_index": seat_idx,
			"hand": [],
			"score": 0,
			"is_ai": true
		})
	players.sort_custom(func(a, b): return a.seat_index < b.seat_index)
	
	print("Active players for this round (in table order):")
	for p in players:
		print(p.name, " at Seat", p.seat_index)
	print("players looks like: ", players)
	
func deal_hands(players: int):pass

func create_deck():
	deck.clear()
	var suits = ["Hearts", "Diamonds", "Clubs", "Spades"]
	var ranks = {
		"Two": 2, "Three": 3, "Four": 4, "Five": 5, "Six": 6, "Seven": 7, 
		"Eight": 8, "Nine": 9, "Ten": 10, "Jack": 10, "Queen": 10, "King": 10, "Ace": 11
	}
	for s in suits:
		for r in ranks.keys():
			deck.append(CardData.new(s, r, ranks[r]))

func shuffle_deck():
	deck.shuffle() # Simple, fast, reliable.

func calculate_player_score(player_hand) -> int:
	var score = 0
	var ace_count = 0
	for card_data in player_hand:
		score += card_data.value
		if card_data.rank == "Ace":
			ace_count += 1
	
	# Devalue Aces from 11 to 1 if the score is over 21
	while score > 21 and ace_count > 0:
		score -= 10
		ace_count -= 1
		
	return score

func reset_data():	
	dealer_hand.score = 0
	dealer_hand.hand.clear()

	
