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
var player_count: int
const CARD_SCENE := preload("res://card.tscn")
const PLAYER_AREA_SCENE := preload("res://player_area.tscn")

var deck: Array = []
var player_hands: Array = []
var dealer_hand: Dictionary = {"hand": [], "score": 0}
var current_turn_index: int = -1
var players: Array = []
@onready var ui_manager = $UIManager
@onready var table = $Table

func _ready() -> void:	
	ui_manager.start_button_pressed.connect(_on_start_game)

func _on_start_game(ai_players: int):	
	ui_manager.hide_start_menu()
	_create_player_data(ai_players)
	
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
			"name": f"AI {i + 1}",
			"hand": [],
			"score": 0,
			"is_ai": true
		})
	
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
	player_hands.clear()
	dealer_hand.score = 0
	dealer_hand.hand.clear()

	
