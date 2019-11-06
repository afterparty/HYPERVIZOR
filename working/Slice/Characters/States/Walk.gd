extends Node2D

func update_state(player):
	if (!Input.is_action_pressed("player_right")
	and !Input.is_action_pressed("player_left")):
		player.current_state = player.states["idle"]
