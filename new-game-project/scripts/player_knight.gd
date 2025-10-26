extends CharacterBody2D

var speed : float = 75
var can_move : bool = true:
	set(value):
		can_move = value
		if value == false:
			speed = 0
		else:
			speed = 75

func _physics_process(delta):
	velocity = input.get_vector("ui_left","ui_right","ui_up","ui_down") * speed
	move_and_slide()
