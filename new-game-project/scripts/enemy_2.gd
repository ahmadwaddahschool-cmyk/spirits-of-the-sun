extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 50.0
const CHASE_RANGE = 200.0
const ATTACK_RANGE = 40.0
const ATTACK_DAMAGE = 4
const MAX_HEALTH = 10

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = MAX_HEALTH
var player = null
var is_attacking = false
var is_hurt = false
var is_dead = false
var attack_cooldown = 0.0
var locked_y_position = 0.0

func _ready():
	print("Enemy spawned with health: ", health)
	# Connect animation finished signal
	if animated_sprite_2d:
		animated_sprite_2d.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# Don't process if dead
	if is_dead:
		return
	
	# Apply gravity (same as player)
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Lock Y position during hurt or attack (same as player)
	if is_hurt or is_attacking:
		velocity.x = 0
		velocity.y = 0
		position.y = locked_y_position
		move_and_slide()
		# Update locked position when on floor
		if is_on_floor() and not is_attacking and not is_hurt:
			locked_y_position = position.y
		return
	
	# Find player if not already found
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if player != null and not player.is_queued_for_deletion():
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# Flip sprite to face player
		if player.global_position.x < global_position.x:
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
		
		# Check if in attack range
		if distance_to_player <= ATTACK_RANGE and attack_cooldown <= 0 and is_on_floor():
			attack_player()
		# Check if in chase range
		elif distance_to_player <= CHASE_RANGE:
			chase_player()
		else:
			# Idle
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if animated_sprite_2d:
				animated_sprite_2d.play("idle")
	else:
		# No player, just idle
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if animated_sprite_2d:
			animated_sprite_2d.play("idle")
	
	# Move and slide (same as player)
	move_and_slide()
	
	# Update locked position if on floor (same as player)
	if is_on_floor() and not is_attacking and not is_hurt:
		locked_y_position = position.y

func chase_player():
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * SPEED
	
	# Play run animation
	if animated_sprite_2d:
		animated_sprite_2d.play("run")

func attack_player():
	is_attacking = true
	attack_cooldown = 1.5  # 1.5 seconds between attacks
	locked_y_position = position.y
	velocity.x = 0
	velocity.y = 0
	
	# Play run+attack animation
	if animated_sprite_2d:
		if animated_sprite_2d.sprite_frames.has_animation("run + attack"):
			animated_sprite_2d.play("run + attack")
		else:
			# Fallback if run+attack doesn't exist
			animated_sprite_2d.play("idle")
	
	# Deal damage to player in the middle of attack animation
	await get_tree().create_timer(0.3).timeout
	
	if player != null and not player.is_queued_for_deletion():
		if player.has_method("take_damage"):
			player.take_damage(ATTACK_DAMAGE)
			print("Enemy attacked player for ", ATTACK_DAMAGE, " damage!")

func take_damage(amount):
	if is_dead:
		return
	
	health -= amount
	print("Enemy took ", amount, " damage! Health: ", health)
	
	if health <= 0:
		die()
	else:
		# Play hurt animation
		is_hurt = true
		locked_y_position = position.y
		velocity.x = 0
		velocity.y = 0
		if animated_sprite_2d:
			animated_sprite_2d.play("hurt")

func die():
	is_dead = true
	velocity.x = 0
	velocity.y = 0
	print("Enemy died!")
	
	# Play death animation
	if animated_sprite_2d:
		animated_sprite_2d.play("dead")
	
	# Wait for death animation to finish, then remove
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_animation_finished():
	var current_anim = animated_sprite_2d.animation
	
	# Reset hurt state after hurt animation
	if current_anim == "hurt":
		is_hurt = false
	
	# Reset attack state after attack animation
	if current_anim == "run + attack":
		is_attacking = false
