extends Node2D

@onready var _MainWindow = get_window()
#@onready var char_sprite: AnimatedSprite2D = $Character/AnimatedSprite2D
@onready var character: Node2D = $Character
@onready var emitter: CPUParticles2D = $Character/CPUParticles2D

var player_size: Vector2i = Vector2i(110,70)
#The offset between the mouse and the character
var mouse_offset: Vector2 = Vector2.ZERO
var selected: bool = false
#If true the character will move
var is_walking: bool = false
var walk_direction: int = 1
#Character walk speed
const WALK_SPEED = 80

func _ready():
	#Change the size of the window
	_MainWindow.min_size = player_size
	_MainWindow.size = _MainWindow.min_size
	#Places the character in the middle of the screen and on top of the taskbar
	_MainWindow.position = Vector2i(DisplayServer.screen_get_size().x/2 - (player_size.x/2), get_pos_in_taskbar())

func get_current_usable_screen_rect() -> Rect2:
	#print(_MainWindow.position)
	var mouse_pos = _MainWindow.position# DisplayServer.mouse_get_position()
	var current_screen:int
	var screen_rect:Rect2
	for i in DisplayServer.get_screen_count():
		var pos = DisplayServer.screen_get_position(i)
		var size = DisplayServer.screen_get_size(i)
		#printt(i, pos, size, mouse_pos)
		if mouse_pos.x >= pos.x and mouse_pos.x <= pos.x + size.x:
			if mouse_pos.y >= pos.y and mouse_pos.y <= pos.y + size.y:
				current_screen = i
				screen_rect = Rect2(pos, size)
				break
	
	#if not screen_rect:
		#return DisplayServer.screen_get_usable_rect(0)
	
	return screen_rect

func _process(delta):
	get_current_usable_screen_rect()
	if selected:
		follow_mouse()
	if is_walking:
		walk(delta)
	move_pet()
	#emit heart particles when petted
	if Input.is_action_just_pressed("pet"):
		emitter.emitting = true

func get_pos_in_taskbar():
	return get_current_usable_screen_rect().position.y + get_current_usable_screen_rect().size.y - player_size.y + 5

func follow_mouse():
	#Follows mouse cursor but clamps it on the taskbar
	_MainWindow.position = Vector2i(clamp_on_screen_width((get_global_mouse_position().x 
		 + mouse_offset.x),
		 player_size.x), get_pos_in_taskbar()) 
	#_MainWindow.position.x = get_global_mouse_position().x + mouse_offset.x
	#_MainWindow.position.y = clamp_to_task_bar(get_global_mouse_position().x + mouse_offset.x)
		##clamp_on_screen_width(
			##(, player_size.x),
			##taskbar_y) 

func move_pet():
	#On right click and hold it will follow the pet and when released
	#it will stop following
	if Input.is_action_pressed("move"):
		selected = true
		mouse_offset = _MainWindow.position - Vector2i(get_global_mouse_position()) 
	if Input.is_action_just_released("move"):
		selected = false

func clamp_on_screen_width(pos, player_width):
	return clampi(pos, 0, multi_screen_extents().x - player_width)

#func clamp_on_screen_width(x:float) -> int:
	## clamps in furthest x directions wrt player size
	## down to taskbar
	#
	#return clampi(x, 0, multi_screen_extents().x - player_size.x)
	
func clamp_to_task_bar(x:float):
	var rect = get_current_usable_screen_rect()
	return rect.position.y + rect.size.y

func multi_screen_extents() -> Vector2:
	var extents := Vector2.ZERO
	for i in DisplayServer.get_screen_count():
		var rect = DisplayServer.screen_get_usable_rect(i)
		
		extents.x = max(extents.x, rect.position.x + rect.size.x)
		extents.y = max(extents.y, rect.position.y + rect.size.y)
	return extents

func walk(delta):
	if not character.can_move_in_walk():
		return
	#Moves the pet
	_MainWindow.position.x = _MainWindow.position.x + WALK_SPEED * delta * walk_direction
	#Clamps the pet position on the width of screen
	_MainWindow.position.x = clampi(_MainWindow.position.x, 0
			,clamp_on_screen_width(_MainWindow.position.x, player_size.x))
	_MainWindow.position.y = get_pos_in_taskbar()
	#Changes direction if it hits the sides of the screen
	if ((_MainWindow.position.x >= (multi_screen_extents().x - player_size.x)) or (_MainWindow.position.x <= 0)):
		walk_direction = walk_direction * -1
		character.reverse_flip()

func choose_direction():
	if (randi_range(1,2) == 1):
		walk_direction = 1
		character.set_flip(false)
		#char_sprite.flip_h = false
	else:
		walk_direction = -1
		character.set_flip(true)

func _on_character_walking():
	is_walking = true
	choose_direction()

func _on_character_finished_walking():
	is_walking = false
