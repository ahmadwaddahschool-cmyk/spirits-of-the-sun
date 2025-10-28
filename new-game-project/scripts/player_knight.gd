extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var speed : float = 75
var can_move : bool = true:
	set(value):
		can_move = value
		if value == false:
			speed = 0
		else:
			speed = 75

func _physics_process(delta):
	velocity = Input.get_vector("ui_left","ui_right","ui_up","ui_down") * speed
	move_and_slide()

	if can_move:
		if velocity == Vector2.ZERO:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")

		if velocity.x < 0:
			animated_sprite_2d.flip_h = true
		elif velocity.x > 0:
			animated_sprite_2d.flip_h = false
