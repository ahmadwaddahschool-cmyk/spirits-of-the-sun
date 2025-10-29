extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_scene = preload("res://scenes/attack_enemy.tscn")

const SPEED = 50.0
const ATTACK_DAMAGE = 5
const MAX_HEALTH = 10
const ATTACK_RANGE = 50.0
const STOP_DISTANCE = 40.0
const ATTACK_COOLDOWN = 2.0
const DETECTION_RANGE = 200.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = MAX_HEALTH
var is_attacking = false
var attack_timer = 0.0
var attack_cooldown_timer = 0.0
var locked_y_position = 0.0
var player = null

func _ready():
	print("Enemy spawned with health: ", health)
	# Add to enemy group
	add_to_group("enemy")
	
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Warning: No player found! Make sure player is in 'player' group")

func _physics_process(delta):
	# Handle attack timer
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
			print("Enemy attack finished")
	
	# Handle attack cooldown
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# AI behavior
	if player and is_instance_valid(player):
		var distance_to_player = position.distance_to(player.position)
		
		# Check if player is in detection range
		if distance_to_player < DETECTION_RANGE:
			# Check if player is in attack range
			if distance_to_player < ATTACK_RANGE and is_on_floor() and not is_attacking and attack_cooldown_timer <= 0:
				perform_attack()
			elif not is_attacking and distance_to_player > STOP_DISTANCE:
				# Only move if farther than stop distance
				move_towards_player(distance_to_player)
			elif not is_attacking:
				# Stop and idle when close
				velocity.x = move_toward(velocity.x, 0, SPEED * 2)
				animated_sprite_2d.play("idle")
				
				# Face the player
				if player.position.x > position.x:
					animated_sprite_2d.flip_h = false
				else:
					animated_sprite_2d.flip_h = true
		elif not is_attacking:
			# Idle when player is far
			animated_sprite_2d.play("idle")
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# No player, just idle
		if not is_attacking:
			animated_sprite_2d.play("idle")
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# During attack, lock vertical movement and stop horizontal
	if is_attacking:
		velocity.y = 0
		position.y = locked_y_position
		velocity.x = move_toward(velocity.x, 0, SPEED * 3)
	
	move_and_slide()
	
	# Update locked position if on floor and not attacking
	if is_on_floor() and not is_attacking:
		locked_y_position = position.y

func move_towards_player(distance: float):
	# Don't move if too close
	if distance < STOP_DISTANCE:
		velocity.x = move_toward(velocity.x, 0, SPEED * 2)
		return
	
	var direction = sign(player.position.x - position.x)
	
	# Flip sprite based on direction
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
	
	# Move towards player
	velocity.x = direction * SPEED
	
	# Play walk animation
	if is_on_floor():
		animated_sprite_2d.play("walk")

func perform_attack():
	is_attacking = true
	attack_cooldown_timer = ATTACK_COOLDOWN
	
	# Lock the Y position at attack start
	locked_y_position = position.y
	velocity.y = 0
	velocity.x = 0
	
	# Face the player before attacking
	if player and is_instance_valid(player):
		if player.position.x > position.x:
			animated_sprite_2d.flip_h = false
		else:
			animated_sprite_2d.flip_h = true
	
	# Play attack animation
	animated_sprite_2d.play("attack")
	attack_timer = 1.0
	
	# Spawn attack hitbox
	spawn_attack_hitbox()
	print("Enemy attacking!")

func spawn_attack_hitbox():
	var attack_instance = attack_scene.instantiate()
	
	# Position the attack in front of the enemy
	var attack_offset = 30 if not animated_sprite_2d.flip_h else -30
	attack_instance.position = position + Vector2(attack_offset, 0)
	
	# Pass damage value and owner to the attack
	if attack_instance.has_method("set_damage"):
		attack_instance.set_damage(ATTACK_DAMAGE)
	if attack_instance.has_method("set_owner_type"):
		attack_instance.set_owner_type("enemy")
	
	# Add to parent (scene root)
	get_parent().add_child(attack_instance)

func take_damage(amount):
	health -= amount
	print("Enemy took ", amount, " damage! Health: ", health)
	
	if health <= 0:
		die()

func die():
	print("Enemy died!")
	queue_free()
