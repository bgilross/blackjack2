extends CanvasLayer # Using a CanvasLayer is best practice for UI

# Define signals that the GameManager will listen for.
signal new_deal_pressed
signal hit_pressed
signal stay_pressed

# Node references
@onready var new_deal_button: Button = $Menu/NewDeal_button
@onready var hit_button: Button = $Menu/Hit_button
@onready var stay_button: Button = $Menu/Stay_button
@onready var player_hand_score_label: Label = $PlayerHandScoreLabel
@onready var dealer_hand_score_label: Label = $DealerHandScoreLabel
@onready var player_total_score_label: Label = $PlayerScoreLabel
@onready var dealer_total_score_label: Label = $DealerScoreLabel
@onready var result_banner_label: Label = $ResultsBannerLabel # Add a big label in the center

func _ready() -> void:
	# Connect the button's 'pressed' signal to a local handler
	new_deal_button.pressed.connect(_on_NewDealButton_pressed)
	hit_button.pressed.connect(_on_HitButton_pressed)
	stay_button.pressed.connect(_on_StayButton_pressed)

	result_banner_label.hide()

# --- UI Update Functions ---

func show_ready_ui():
	new_deal_button.show()
	new_deal_button.disabled = false
	hit_button.hide()
	stay_button.hide()
	result_banner_label.hide()

func show_gameplay_ui(player_can_act: bool):
	new_deal_button.hide()
	hit_button.show()
	stay_button.show()
	hit_button.disabled = not player_can_act
	stay_button.disabled = not player_can_act

# --- Button Handlers (Emit signals to GameManager) ---

func _on_NewDealButton_pressed():
	emit_signal("new_deal_pressed")

func _on_HitButton_pressed():
	emit_signal("hit_pressed")

func _on_StayButton_pressed():
	emit_signal("stay_pressed")

# --- GameManager Signal Handlers (Listening for events) ---

func _on_hand_score_updated(player_score: int, dealer_score: int):
	player_hand_score_label.text = "Hand: " + str(player_score)
	dealer_hand_score_label.text = "Hand: " + str(dealer_score)

func _on_total_score_updated(player_total: int, dealer_total: int):
	player_total_score_label.text = "Player: " + str(player_total)
	dealer_total_score_label.text = "Dealer: " + str(dealer_total)

func _on_player_busted(score: int):
	_show_result_banner("Player Busts!", Color.FIREBRICK)

func _on_winner_determined(winner: String, reason: String):
	var color = Color.GOLD
	if winner == "Dealer":
		color = Color.LIGHT_CORAL
	elif winner == "Push":
		color = Color.LIGHT_GRAY
		
	_show_result_banner(winner + " Wins!\n" + reason, color)

# --- Visual Flair Helper ---

func _show_result_banner(text: String, color: Color):
	result_banner_label.text = text
	result_banner_label.modulate = color
	result_banner_label.pivot_offset = result_banner_label.size / 2.0
	result_banner_label.scale = Vector2.ZERO
	result_banner_label.show()

	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_banner_label, "scale", Vector2.ONE, 0.6)
