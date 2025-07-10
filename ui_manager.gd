extends CanvasLayer

signal start_button_pressed (player_count: int) #i wanted default to be one but signal parameters cannot have default values, maybe there is a better way besides signals...?

@onready var start_button: Button = $StartMenu/StartButton
@onready var player_count_dropdown: OptionButton = $StartMenu/PlayerCount/PlayerCountOption
@onready var table: Node2D = $"../Table"
@onready var start_menu: Control = $StartMenu

func _ready() -> void:
	start_button.pressed.connect(_on_StartButton_pressed)
	
func _on_StartButton_pressed():
	#get player count from dropdown:
	#looks like we need to get selected index first?	
	var player_count = _get_player_count()
	start_button_pressed.emit(player_count)
	
func _get_player_count():
	var selected_id = player_count_dropdown.get_selected_id()
	var selected_index = player_count_dropdown.get_item_index(selected_id)
	var player_count = player_count_dropdown.get_item_text(selected_index)
	var player_count_int = player_count.to_int()
	return player_count_int
	
func hide_start_menu():
	start_menu.visible = false
	
