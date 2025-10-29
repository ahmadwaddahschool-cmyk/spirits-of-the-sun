extends Area2D

var damage = 5
var attack_owner = ""  # "player" or "enemy"

func _ready():
	# Connect to body_entered signal
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after a short time
	await get_tree().create_timer(0.2).timeout
	queue_free()

func set_damage(value):
	damage = value

func set_owner_type(owner_type: String):
	attack_owner = owner_type

func _on_body_entered(body):
	print("Attack hit something: ", body.name, " | Owner: ", attack_owner)
	
	# Only damage the opposite type
	if attack_owner == "player" and body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Player hit enemy for ", damage, " damage!")
	elif attack_owner == "enemy" and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Enemy hit player for ", damage, " damage!")
