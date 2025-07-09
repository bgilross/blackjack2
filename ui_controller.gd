extends Node


func _on_GameManager_player_busted(score):
	# Trigger a "BUST!" animation on the player's side
	# Play a disappointing sound effect
	# Shake the screen slightly
	print("UI: Player has busted with a score of ", score)

func _on_GameManager_winner_determined(winner, reason):
	# Display a large text banner showing the winner and why
	# Trigger a particle effect (confetti for player win, etc.)
	print("UI: ", winner, " wins! Reason: ", reason)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
