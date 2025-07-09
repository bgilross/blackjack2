extends Node2D

@onready var name_label: Label = $NameLabel
@onready var score_label: Label = $ScoreLabel
@onready var hand_parent: Node2D = $HandParent

func setup(player_name: String):
	name = player_name # Set the Node's own name for easier debugging in the scene tree
	name_label.text = player_name
	score_label.text = "0"
	score_label.modulate = Color.WHITE

func update_display(score: int, is_busted: bool) -> void:
	if is_busted:
		score_label.text = "BUST"
		score_label.modulate = Color.FIREBRICK
	else:
		score_label.text = str(score)
		score_label.modulate = Color.WHITE

func get_hand_parent() -> Node2D:
	return hand_parent

func set_active_turn(is_active: bool) -> void:
	# Using a tween for a smoother visual effect.
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	if is_active:
		tween.tween_property(name_label, "modulate", Color.GOLD, 0.2)
		tween.tween_property(name_label, "scale", Vector2(1.2, 1.2), 0.2)
	else:
		tween.tween_property(name_label, "modulate", Color.WHITE, 0.2)
		tween.tween_property(name_label, "scale", Vector2.ONE, 0.2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
