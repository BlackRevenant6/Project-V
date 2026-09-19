extends CharacterBody2D

class_name player_

var melee_target = world.center
var melee_target_list = []
var ranged_target = world.center
var ranged_target_list = []
var spawn_slash
var spawn_arrow

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Anim.play("idle_right")
	$shield_anim.visible = false
	$HUD/Dash.visible = false
	$HUD/Block.visible = false
	$HUD/Slash.visible = false
	$HUD/Bow.visible = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if world.reset == true or Player.power_up_count == 8:
		queue_free()
	
	#GET POSITION
	Player.position = global_position
	
	#ANIM SPEED CHANGES
	$Anim.speed_scale = Player.anim_speed
	
	#DEATH
	if Player.health < 1:
		queue_free()
	
	#TRACK POWER UPS
	match Player.power_up_count:
		1:
			Player.unlock_dash = true
			$HUD/Dash.visible = true
		2:
			Player.unlock_shield = true
			$HUD/Block.visible = true

		3:
			Player.unlock_attack = true
			$HUD/Slash.visible = true

		4:
			Player.unlock_parry = true

		5:
			Player.unlock_shadow_form = true

		6:
			Player.unlock_bow = true
			$HUD/Bow.visible = true
	$HUD/objective/amount.text = str(Player.power_up_count)
	
	#UPDATE HUD
	if $HUD/Block_timer.is_stopped():
		$HUD/Block/cd.text = "Ready"
		$HUD/Block.play("ready")
	else:
		$HUD/Block/cd.text = str(snappedf($HUD/Block_timer.time_left,0.1))
		$HUD/Block.play("on_cd")
	
	if $HUD/Dash_timer.is_stopped():
		$HUD/Dash/cd.text = "Ready"
		$HUD/Dash.play("ready")
	else:
		$HUD/Dash/cd.text = str(snappedf($HUD/Dash_timer.time_left,0.01))
		$HUD/Dash.play("on_cd")
	
	if $HUD/Slash_timer.is_stopped():
		$HUD/Slash/cd.text = "Ready"
		$HUD/Slash.play("ready")
	else:
		$HUD/Slash/cd.text = str(snappedf($HUD/Slash_timer.time_left,0.1))
		$HUD/Slash.play("on_cd")
	
	if $HUD/Bow_timer.is_stopped():
		$HUD/Bow/cd.text = "Ready"
		$HUD/Bow.play("ready")
	else:
		$HUD/Bow/cd.text = str(snappedf($HUD/Bow_timer.time_left,0.1))
		$HUD/Bow.play("on_cd")
	
	#BASE MOVEMENT
	var input_direction = Input.get_vector("left","right","up","down")
	velocity = input_direction * Player.base_speed * Player.speed_modifier * delta
	move_and_slide()
	
	#WALK AND IDLE
	match input_direction[0]:
		1.0: 
			$Anim.play("walk_right")
			Player.last_direction = "right"
		-1.0:
			$Anim.play("walk_left")
			Player.last_direction = "left"
		_:
			match input_direction[1]:
				1.0:
					$Anim.play("walk_down")
					Player.last_direction = "down"
					
				-1.0:
					$Anim.play("walk_up")
					Player.last_direction = "up"
				_: 
					if input_direction[0] > 0:
						if input_direction[1] > 0:
							$Anim.play("walk_down_right")
							Player.last_direction = "down_right"
						if input_direction[1] < 0:
							$Anim.play("walk_up_right")
							Player.last_direction = "up_right"
					if input_direction[0] < 0:
						if input_direction[1] > 0:
							$Anim.play("walk_down_left")
							Player.last_direction = "down_left"
						if input_direction[1] < 0:
							$Anim.play("walk_up_left")
							Player.last_direction = "up_left"
	#IDLE
					if input_direction[0] == 0.0 and input_direction[1] == 0.0:
						match Player.last_direction:
							"right":
								$Anim.play("idle_right")
							"left":
								$Anim.play("idle_left")
							"up":
								$Anim.play("idle_up")
							"down":
								$Anim.play("idle_down")
							"up_right":
								$Anim.play("idle_up_right")
							"up_left":
								$Anim.play("idle_up_left")
							"down_right":
								$Anim.play("idle_down_right")
							"down_left":
								$Anim.play("idle_down_left")
	
	#DASH/SHADOW FORM
	if (Input.is_action_pressed("dash")
		and Player.unlock_dash
		and Player.can_dash 
		and not(Player.effect_list.has("slow"))):
		
		$HUD/Dash_timer.start(2.5)
		Player.effect_list.append("dash")
		
		if Player.unlock_shadow_form:
			Player.effect_list.append("invincible")
	
	
	#ATTACK
		#slash
	if Player.unlock_attack:
		#find closest target in melee range
		melee_target_list = $melee_attack_range.get_overlapping_bodies()
		melee_target_list.erase(self)
		if melee_target_list == []:
			melee_target = world.center
		for i in melee_target_list:
			if (i.global_position.distance_to(Player.position)
			< (melee_target.global_position.distance_to(Player.position))
			and i != self):
				melee_target = i
				
	if (Input.is_action_pressed("slash") 
		and melee_target_list 
		and melee_target != world.center
		and Player.unlock_attack
		and $slash_cooldown.is_stopped()):
			
		spawn_slash = preload("res://slash.tscn")
		spawn_slash = spawn_slash.instantiate()
		spawn_slash.rotation = get_angle_to(melee_target.global_position) + 90
		self.add_child(spawn_slash)
		
		Ennemy.take_damage.append(melee_target)
		melee_target = world.center
		$slash_cooldown.start(1)
		$HUD/Slash_timer.start(1)
			
	# SHOOT BOW
	if Player.unlock_bow:
		#find closest target in ranged range
		ranged_target_list = $ranged_attack_range.get_overlapping_bodies()
		ranged_target_list.erase(self)
		print(ranged_target_list)
		if ranged_target_list == []:
				ranged_target = world.center
		for i in ranged_target_list:
			if (i.global_position.distance_to(Player.position)
			< (ranged_target.global_position.distance_to(Player.position))
			and i != self):
				ranged_target = i
				
				
	if (Input.is_action_pressed("shoot_bow")
	and ranged_target_list
	and ranged_target != null 
	and melee_target_list.find(ranged_target)
	and Player.unlock_bow
	and $bow_cooldown.is_stopped()):
		print(melee_target_list.find(ranged_target))
		print("ok")
		spawn_arrow = preload("res://arrow.tscn")
		spawn_arrow = spawn_arrow.instantiate()
		spawn_arrow.rotation = get_angle_to(ranged_target.global_position) + 90
		self.add_child(spawn_arrow)
		
		Ennemy.take_damage.append(ranged_target)
		ranged_target = world.center
		$bow_cooldown.start(1)
		$HUD/Bow_timer.start(1)
		
	#BLOCK / PARRY
	if (Input.is_action_pressed("block")
		and Player.unlock_shield
		and Player.can_block):
		Player.can_block = false
		$shield_anim.visible = true
		$HUD/Block_timer.start(Player.block_time + Player.block_cooldown)
		$blocking.start(Player.block_time)
		Player.effect_list.append("block")
	

	
	#BLOCK / PARRY (deflects(animations reported to later :-( ))
	#Ideas
		# shield has 3 charges
		# blocking consumes one charge and negates all damage (knocks u back a bit)
		# parry consumes no charges and counter attack / dodge / stuns ennemy
	# Parry vs ennemy (just gonna shoot a laser for now :-(
		# vs slime (green)
			# vs slimeball just dispawns
			# vs slime spike grab it, spin and slam the slime on a wall (big damage)
			# vs pounce dodges lets it splat on the ground (stuns)
		# vs squeleton archer
			# vs arrow grab it and return to sender
			# vs punch grabs arm and tries to judo throw but arm rips off (can't use bow anymore)
			# vs grapple hook grabs the hook and pull it, enemy falls on the ground (stuns)




func _on_blocking_timeout() -> void:
	$shield_anim.visible = false
