extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var timer = $Timer

var pet_state : int = STATE.IDLE

#signals to send when entering and leaving states
signal walking
signal finished_walking

enum STATE{
	IDLE,
	LOOKAROUND,
	WALK,
	SLEEP,
}

func _ready():
	pet_state = STATE.LOOKAROUND
	play("look_around")
	timer.start()

func set_flip(left:bool):
	var suffix : String
	if sprite.flip_h:
		suffix = "left"
	else:
		suffix = "right"
	var name_base = str(sprite.animation).trim_suffix(str("_", suffix))
	sprite.flip_h = left
	play(name_base)

func reverse_flip():
	set_flip(not sprite.flip_h)

func play(anim_name:String):
	var suffix : String
	if sprite.flip_h:
		suffix = "left"
	else:
		suffix = "right"
	sprite.play(str(anim_name, "_", suffix))

func _on_timer_timeout():
	if pet_state == STATE.WALK:
		finished_walking.emit()
	
	await change_state()
	#Timer can change according to state and is random
	match pet_state:
		STATE.IDLE :
			timer.set_wait_time(randi_range(10, 200))
			play("idle")
		STATE.LOOKAROUND :
			timer.set_wait_time(randi_range(2, 4))
			play("look_around")
		STATE.WALK :
			timer.set_wait_time(randi_range(5, 60))
			play("walk")
		STATE.SLEEP :
			timer.set_wait_time(randi_range(300, 1000))
			play("sleep")
	timer.start()

func change_state():
	pet_state = randi_range(0,3)
	if pet_state == STATE.WALK:
		walking.emit()

func can_move_in_walk():
	return sprite.frame > 1 and sprite.frame < 6
