extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@export var speed = 80
@export var attack_range = 40
@export var detection_range = 200
var is_dead = false
@export var health = 10
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0  # يثبت على الأرض

	# مثال بسيط للحركة
	velocity.x = -speed  # يتحرك لليسار
	



	if player == null:
		return
	
	var distance = global_position.distance_to(player.global_position)

	if distance > detection_range:
		# العدو بعيد -> Idle
		anim.play("idle")
		velocity = Vector2.ZERO

	elif distance > attack_range:
		# العدو شاف اللاعب -> يركض نحوه
		anim.play("run")
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

	else:
		# العدو قريب -> يهاجم
		anim.play("attack")
		velocity = Vector2.ZERO
		

func take_damage(amount):
	if is_dead:
		return
	health -= amount
	print("Enemy HP:", health)
	if health <= 0:
		die()
		
func die():
	is_dead = true
	anim.play("dead")
	velocity = Vector2.ZERO
	await anim.animation_finished
	queue_free()
