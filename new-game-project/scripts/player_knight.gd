extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_scene = preload("res://scenes/Attack.tscn")

const SPEED = 70.0
const RUN_SPEED = 110.0
const JUMP_VELOCITY = -300.0
const ATTACK_DAMAGE = 5
const MAX_HEALTH = 20

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking = false
var attack_timer = 0.0
var locked_y_position = 0.0
var health = MAX_HEALTH

func _ready():
	print("Player health: ", health)

func _physics_process(delta):
	# Handle attack timer
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
			print("Attack finished by timer")
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY
	
	# Handle attack
	if Input.is_action_just_pressed("ui_attack") and is_on_floor() and not is_attacking:
		perform_attack()
	
	# Get input direction: -1, 0, 1
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Check if Shift is pressed (for running)
	var is_running = Input.is_action_pressed("ui_shift")
	var current_speed = RUN_SPEED if is_running else SPEED
	
	# Flip sprite depending on direction (not during idle attack)
	if not is_attacking or is_running:
		if direction > 0:
			animated_sprite_2d.flip_h = false
		elif direction < 0:
			animated_sprite_2d.flip_h = true
	
	# Play animations (only if not attacking)
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite_2d.play("idle")
			else:
				if is_running:
					animated_sprite_2d.play("run")
				else:
					animated_sprite_2d.play("walk")
		else:
			animated_sprite_2d.play("jump")
	
	# Apply movement
	if not is_attacking or is_running:
		# Can move freely (normal movement or run+attack)
		if direction:
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# Idle attack - stop horizontal movement
		velocity.x = move_toward(velocity.x, 0, SPEED * 2)
	
	# During ANY ground attack (idle or running), lock vertical movement
	if is_attacking:
		velocity.y = 0
		position.y = locked_y_position
	
	move_and_slide()
	
	# Update locked position if on floor and not attacking
	if is_on_floor() and not is_attacking:
		locked_y_position = position.y

func perform_attack():
	is_attacking = true
	var is_running = Input.is_action_pressed("ui_shift")
	
	# Lock the Y position at attack start
	locked_y_position = position.y
	velocity.y = 0
	
	# Calculate attack duration based on animation
	if is_running:
		if animated_sprite_2d.sprite_frames.has_animation("run + attack"):
			animated_sprite_2d.play("run + attack")
			attack_timer = 1.0
		else:
			animated_sprite_2d.play("attack")
			attack_timer = 1.0
	else:
		animated_sprite_2d.play("attack")
		attack_timer = 1.0
	
	# Spawn attack collision
	spawn_attack_hitbox()
	print("Attack started, timer set to: ", attack_timer)

func spawn_attack_hitbox():
	var attack_instance = attack_scene.instantiate()
	
	# Position the attack in front of the character
	var attack_offset = 30 if not animated_sprite_2d.flip_h else -30
	attack_instance.position = position + Vector2(attack_offset, 0)
	
	# Pass damage value to the attack
	if attack_instance.has_method("set_damage"):
		attack_instance.set_damage(ATTACK_DAMAGE)
	
	# Add to parent (scene root)
	get_parent().add_child(attack_instance)

func take_damage(amount):
	health -= amount
	print("Player took ", amount, " damage! Health: ", health)
	
	# Optional: Add hit animation/effect here
	
	if health <= 0:
		die()

func die():
	print("Player died!")
	# Optional: Play death animation
	queue_free()  # Remove player from scene
