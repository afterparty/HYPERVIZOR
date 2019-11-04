extends "State.gd"

# Instance
export(NodePath) var CHARACTER_PATH
onready var character = get_node(CHARACTER_PATH)
onready var hitbox = owner.get_node("Hitbox")
onready var animation_player = owner.get_node("AnimationPlayer")
var animation_finished := false
var attack
var elapsed_frames = -1

var travel := 0
var travel_dir := 0
var travel_speed := 0.0

func enter():
	find_attack(character.dpad_attack, character.btn_attack)
	if attack != null:
		animation_player.play(attack.ANIMATION)
		animation_finished = false
		print("Attacking")
		elapsed_frames = -1
		character.state = "attack"
		travel = attack.TRAVEL
		travel_dir = attack.TRAVEL_DIR * 1 if character.PLAYER_ID == 1 else -1
		travel_speed = attack.TRAVEL_SPEED
	else:
		print("attack not found")
		emit_signal("finished", "idle")

func find_attack(dpad, btn):
	var state := ''
	if character.is_on_floor():
		state = 'Crouching' if [1, 2, 3].has(dpad) else 'Standing'
	else:
		state = 'Jumping'

	attack = character.get_node('Attacks/' + state + '/' + str(dpad) + '/' + str(btn))
	if attack == null && state == "Crouching":
		state = "Standing"
		attack = character.get_node('Attacks/' + state + '/' + str(dpad) + '/' + str(btn))
	if attack == null:
		attack = character.get_node('Attacks/' + state + '/' + str(5) + '/' + str(btn))
		dpad = 5
		if attack == null && len(str(btn)) > 1:
			attack = character.get_node('Attacks/' + state + '/' + str(5) + '/' + str(btn)[1])
			btn = int(str(btn)[1])

	hitbox.CURRENT_ATTACK = attack
	character.flush_input_buffer()

	print(' ')
	print(attack)
	print(str(dpad) + str(btn))
	print(' ')

func handle_input(event):
	return .handle_input(event)

func update(delta):
	elapsed_frames += 1
	var temp_buffer = character.input_buffer
	hitbox.CURRENT_ATTACK = attack

	if character.is_on_floor():
		character.move_dir = travel_dir

	character.y_velo += character.GRAVITY

	if character.y_velo > character.MAX_FALL_SPEED:
		character.y_velo = character.MAX_FALL_SPEED

	character.move_and_slide(Vector2(character.move_dir * travel * travel_speed * character.JUMP_X_FORCE, character.y_velo), Vector2(0, -1))

	if travel > 0:
		travel -= 1

	var buffered_btn = character.find_buffered_btn(temp_buffer, attack.FOLLOWUP_BTNS, attack.CANCEL)

	if buffered_btn != null && attack.FOLLOWUP_BTNS.has(buffered_btn) && elapsed_frames >= attack.CANCEL && attack.CANCEL > 0:
		elapsed_frames = 0
		var attack_was = attack
		attack = attack.get_node(str(buffered_btn)) if attack.get_node(str(buffered_btn)) != null else attack
		if attack != null && attack != attack_was:
			travel = attack.TRAVEL
			travel_dir = attack.TRAVEL_DIR * 1 if character.PLAYER_ID == 1 else -1
			travel_speed = attack.TRAVEL_SPEED
			animation_player.stop()
			animation_player.play(attack.ANIMATION)

	if animation_finished && !character.is_on_floor():
		hitbox.CURRENT_ATTACK = null
		emit_signal("finished", "land")
	elif animation_finished:
		hitbox.CURRENT_ATTACK = null
		emit_signal("finished", "idle")


func _on_animation_finished(anim_name):
	if attack != null:
		if anim_name == attack.ANIMATION:
			animation_finished = true
