extends Node

enum GameState {
	MENU,
	SETUP,
	PLAYER_TURN,
	AI_TURN,
	DEALER_TURN,
	ROUND_OVER,
}

var current_state: GameState = -1

const CARD_SCENE := preload("res://card.tscn")
const PLAYER_AREA_SCENE := preload("res://player_area.tscn")

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

func _on_table_setup_complete():
	#tell the UI to get allow the deal button/ whatever will start round to be allowed.
	ui_manager.enter_round_start()
	
func _on_start_game(ai_players: int):	
	ui_manager.hide_start_menu()
	_create_player_data(ai_players)
	table.setup_table(players)
	
func _create_player_data(ai_players: int):
	players.clear()
	players.append({
		"name": "Player",
		"hand": [],
		"score": 0,
		"is_ai": false
	})
	
	for i in range(ai_players):
		players.append({
			"name": "AI " + str(i+1),
			"hand": [],
			"score": 0,
			"is_ai": true
		})
	
	print("created player data: ", players)
	
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

	
