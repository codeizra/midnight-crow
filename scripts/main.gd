extends Node

#preload obstacles
var grave_scene = preload("res://scenes/grave.tscn")
var grave_2_scene = preload("res://scenes/grave_2.tscn")
var obstacle_types := [grave_scene, grave_2_scene]
var obstacles : Array

# game variables
const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)

var difficulty
const MAX_DIFFICULTY : int = 2

var score : int
const SCORE_MODIFIER : int = 100

var high_score : int

var speed : float
const START_SPEED : float = 8.00
const MAX_SPEED 	: int = 25
const SPEED_MODIFIER : int = 5000

var screen_size : Vector2i

var game_running : bool

var last_obs 

var ground_height : int

func _ready():
	screen_size = get_window().size
	$GameOver.get_node("Button").pressed.connect(new_game)
	$Dino.died.connect(_on_dino_died)
	new_game()
	
func new_game():
	#reset var
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0 
	
	#reset obstacles
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	#reset the nodes
	$Dino.position = DINO_START_POS 
	$Dino.velocity = Vector2i(0,0)
	$Dino.get_node("DeathSound").stop()
	$Dino.is_alive = true
	$Dino.get_node("AnimatedSprite2D").play("idle")
	$Camera2D.position = CAM_START_POS
	$Level.position = Vector2i(0,0)
	
	#reset HUD
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

func _process(delta):
	#speed up & adjust difficulty
	if game_running:
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()	
		
		#generate obstacles
		generate_obs()
		
		#move dino & camera
		$Dino.position.x += speed
		$Camera2D.position.x += speed
		
		#update score
		score += speed
		show_score()
			
		#update ground position
		if $Camera2D.position.x - $Level.position.x > screen_size.x * 1.5:
			$Level.position.x += screen_size.x
			
		#remove obstacles that have gone off the screen
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
		
			
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func generate_obs():
	#generate ground obstacles
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var tilemap = obs.get_node("TileMap")  # access the TileMap node
			var tileset = tilemap.tile_set
			var tile_size = tileset.tile_size  # get tile size (e.g., Vector2i(16, 16))
			
			#get the used tile rectangle to determine the height in tiles
			var used_rect = tilemap.get_used_rect()
			var tiles_height = used_rect.size.y  # number of tiles vertically
			
			#calculate the height in pixels
			var obs_height = tiles_height * tile_size.y * tilemap.scale.y
			
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height / 1.5) + 5
			
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		
func add_obs(obs, x, y):
	obs.position = Vector2i(x,y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)
	
func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)
	
func hit_obs(body):
	if body.name == "Dino":
		game_running = false
		$Dino.play_death_animation()
		
func _on_dino_died():
	game_over()  # call game_over after animation finishes
	
func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)
	
func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$GameOver.show()
