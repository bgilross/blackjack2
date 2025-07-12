extends VBoxContainer

@onready var player_score_label: Label = $NameScoreLabel
@onready var hand_score_label: Label = $HandScoreLabel
@onready var hand_container: Control = $HandArea/HandContainer
@onready var center_marker: Marker2D = $HandArea/HandContainer/CenterMarker

func clear_hand():
	for child in hand_container.get_children():
		if not child is Marker2D:
			child.queue_free()

func setup(plr_name: String):
	name = plr_name
	update_display(0, 0, false)	

func update_display(score: int, hand_value: int, busted: bool, winner: bool = false) -> void:
	player_score_label.text = name + ": " + str(score) 
	if busted:
		hand_score_label.text = "BUST " + str(hand_value)
		hand_score_label.modulate = Color.FIREBRICK
		player_score_label.modulate = Color.FIREBRICK
	elif winner:
		hand_score_label.modulate = Color.AQUAMARINE
		player_score_label.modulate = Color.WEB_GREEN		
	else:
		hand_score_label.text =  "Hand: " + str(hand_value)
		hand_score_label.modulate = Color.WHITE

func get_hand_container() -> Control:
	return hand_container

func get_center_marker() -> Marker2D:
	return center_marker

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
