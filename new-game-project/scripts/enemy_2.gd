extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var speed = 70
var player_distacne  = false
var player_knight = null



func _physics_process(delta: float) -> void:
	if player_distacne:
		position += (player_knight.position - position) / speed
		
		

	if not is_on_floor():
		velocity.y += gravity*delta


func _on_player_dis_body_entered(body: Node2D) -> void:
	player_knight = body
	player_distacne = true 
	animated_sprite_2d.play("run")

func _on_player_dis_body_exited(body: Node2D) -> void:
	player_knight = null
	player_distacne = false
