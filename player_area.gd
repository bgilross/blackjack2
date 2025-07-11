extends Control

@onready var player_score_label: Label = $PlayerScoreLabel
@onready var hand_score_label: Label = $HandScoreLabel
@onready var hand_container: Control = $HandSizeTarget/HandContainer

var player_name: String
var current_score
var current_hand_value

func setup(plr_name: String):
	player_name = plr_name # Set the Node's own name for easier debugging in the scene tree
	name = plr_name
	update_display(0, 0, false)
	
func add_card(card_instance: Node2D):
	hand_container.add_child(card_instance)
	hand_container.update_layout()	

func update_score(score: int):
	update_display(score, current_hand_value, false)
func update_hand_value(hand_value: int, is_busted: bool):
	update_display(current_score, hand_value, is_busted)	

func update_display(score: int, hand_value: int, is_busted: bool) -> void:
	player_score_label.text = player_name + ": " + str(score) 
	if is_busted:
		hand_score_label.text = "BUST"
		hand_score_label.modulate = Color.FIREBRICK
	else:
		hand_score_label.text =  "Hand: " + str(hand_value)
		hand_score_label.modulate = Color.WHITE

func get_hand_container() -> Control:
	return hand_container

func set_active_turn(is_active: bool) -> void:
	# Using a tween for a smoother visual effect.
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	if is_active:
		tween.tween_property(player_score_label, "modulate", Color.GOLD, 0.2)
		tween.tween_property(player_score_label, "scale", Vector2(1.2, 1.2), 0.2)
	else:
		tween.tween_property(player_score_label, "modulate", Color.WHITE, 0.2)
		tween.tween_property(player_score_label, "scale", Vector2.ONE, 0.2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
