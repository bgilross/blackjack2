extends Node2D

@export var player_areas: Array[Control]

func setup_table(players_data: Array):
	for area in player_areas:
		area.visible = false
	
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
