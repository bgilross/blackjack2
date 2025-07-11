extends CanvasLayer

signal start_button_pressed (player_count: int) #i wanted default to be one but signal parameters cannot have default values, maybe there is a better way besides signals...?
signal hit_button_pressed
signal stand_button_pressed
signal deal_button_pressed


@onready var start_button: Button = $StartMenu/StartButton
@onready var player_count_dropdown: OptionButton = $StartMenu/PlayerCount/PlayerCountOption
@onready var table: GridContainer = $"../Table"
@onready var start_menu: Control = $StartMenu
@onready var game_ui: Control = $InGameUI
@onready var hit_button: Button = $InGameUI/HitButton
@onready var stand_button: Button = $InGameUI/StandButton
@onready var deal_button: Button = $InGameUI/DealButton

func _ready() -> void:
	start_button.pressed.connect(_on_StartButton_pressed)
	deal_button.pressed.connect(_on_DealButton_pressed)
	hit_button.pressed.connect(_on_HitButton_pressed)
	stand_button.pressed.connect(_on_StandButton_pressed)
	setup_start()

func setup_start():
	game_ui.visible = false
	start_menu.visible = true
	
func _on_StartButton_pressed():
	var player_count = _get_player_count()
	start_button_pressed.emit(player_count)
	
func _on_DealButton_pressed():
	deal_button_pressed.emit()	

func _on_HitButton_pressed():
	hit_button_pressed.emit()

func _on_StandButton_pressed():
	stand_button_pressed.emit()
	
func _get_player_count():
	var selected_id = player_count_dropdown.get_selected_id()
	var selected_index = player_count_dropdown.get_item_index(selected_id)
	var player_count = player_count_dropdown.get_item_text(selected_index)
	var player_count_int = player_count.to_int()
	return player_count_int
	
func enter_round_start():
	#off
	start_menu.visible = false
	stand_button.visible = false
	hit_button.visible = false
	
	#on
	game_ui.visible = true
	deal_button.visible = true
	
func enter_setup():
	start_menu.visible = false
	game_ui.visible = false

func enter_player_turn():
	start_menu.visible = false
	
	game_ui.visible = true
	deal_button.visible = false
	hit_button.visible = true
	stand_button.visible = true

func enter_non_player_turn():
	start_menu.visible = false
	game_ui.visible = false
	
	
	
