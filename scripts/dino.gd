extends CharacterBody2D

signal died  # signal emitted when death animation finishes

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1800

var is_alive : bool = true  # track if Dino is alive to disable physics

func _physics_process(delta):
	if not is_alive:
		return  # skip physics if Dino is dead
	
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		else:
			if Input.is_action_just_pressed("ui_accept"):
				velocity.y = JUMP_SPEED
				$JumpSound.play()
			else:
				$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("jump")
		
	move_and_slide()

func play_death_animation():
	is_alive = false  # disable physics processing
	$AnimatedSprite2D.play("death_2")
	$DeathSound.play()
	await $AnimatedSprite2D.animation_finished
	died.emit()  # notify main script when animation finishes
