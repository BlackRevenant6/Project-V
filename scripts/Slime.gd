extends CharacterBody2D

var hostile = false
var spawn_slimeball = preload("res://slimeball.tscn")
var slimeball_instance
var spawn_slimespike = preload("res://slimespike.tscn")
var slimespike_instance
var next_point
var new_delay
var rand_attack = 0
var specific_cooldown = 0
var combo = false
var hp = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Anim.play("idle")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if world.reset == true or Player.power_up_count == 8:
		queue_free()
		
	for i in Ennemy.take_damage:
		if i == self:
			hp -= 1
			Ennemy.take_damage.erase(i)
			
	if hp < 1:
		queue_free()
	
	if Player.health < 1:
		hostile = false
	# HOSTILE PATHFINDING (basic)
	if hostile == true:
		$Pathfinder.target_position = Player.position
		$Pathfinder.get_next_path_position()
		next_point = to_local($Pathfinder.get_current_navigation_path()[1]).normalized()
		
		velocity = next_point * delta * Ennemy.slime_speed
		if $Pathfinder.distance_to_target() > 30:
			move_and_slide()
		
		#attack
		if (Player.effect_list.has("slow") 
		and not combo 
		and global_position.distance_to(Player.position) < 70):
				rand_attack = 2
				$Attack_delay.stop()
				$Combo_delay.start(4)
				combo = true
				
		if $Attack_delay.is_stopped():
			match rand_attack:
				0,1:
					shoot_slimeball()
					shoot_slimeball()
					shoot_slimeball()
					specific_cooldown = 0.5
					
				2:
					use_slimespike()
					specific_cooldown = 4
					
			
			new_delay = randi_range(0,2) + specific_cooldown
			rand_attack = randi_range(0,2)
			$Attack_delay.start(new_delay)
			
			
				
func shoot_slimeball() -> void:
	slimeball_instance = spawn_slimeball.instantiate()
	owner.add_child(slimeball_instance)
	slimeball_instance.global_position = global_position + to_local(Player.position).normalized()
	
func use_slimespike() -> void:
	slimespike_instance = spawn_slimespike.instantiate()
	self.add_child(slimespike_instance)
	
func _on_aggro_radius_body_entered(body: Node2D) -> void:
	if body is player_:
		hostile = false

func _on_combo_delay_timeout() -> void:
	combo = false
