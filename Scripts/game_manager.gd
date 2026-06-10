extends Node

var current_turn: TargetComponent.Team = TargetComponent.Team.BLUE
var blue_ap: int = 3
var unfired_cannons: int = 0

var red_soldiers_alive: int = 0
var blue_soldiers_alive: int = 0

func _ready() -> void:
	for soldier in get_tree().get_nodes_in_group("Soldiers"):
		if not soldier.is_general:
			var target = soldier.get_node_or_null("TargetComponent")
			if target:
				if target.team == TargetComponent.Team.RED:
					red_soldiers_alive += 1
				elif target.team == TargetComponent.Team.BLUE:
					blue_soldiers_alive += 1
					
	InGameTerminal.log_msg(str("Starting Armies - RED: ", red_soldiers_alive, " | BLUE: ", blue_soldiers_alive))
	call_deferred("start_turn", TargetComponent.Team.BLUE)


func register_soldier_death(team: TargetComponent.Team) -> void:
	if team == TargetComponent.Team.RED:
		red_soldiers_alive -= 1
		InGameTerminal.log_msg(str("Red soldier fell! Remaining: ", red_soldiers_alive))
		if red_soldiers_alive <= 0:
			game_over(TargetComponent.Team.RED) 
			
	elif team == TargetComponent.Team.BLUE:
		blue_soldiers_alive -= 1
		InGameTerminal.log_msg(str("Blue soldier fell! Remaining: ", blue_soldiers_alive))
		if blue_soldiers_alive <= 0:
			game_over(TargetComponent.Team.BLUE) 

func start_turn(team: TargetComponent.Team) -> void:
	current_turn = team
	blue_ap = 3
	unfired_cannons = 0
	
	
	for cannon in get_tree().get_nodes_in_group("Cannons"):
		var target = cannon.get_node_or_null("TargetComponent")
		if target and target.team == current_turn:
			unfired_cannons += 1
			
	var team_name = "RED" if team == TargetComponent.Team.RED else "BLUE"
	InGameTerminal.log_msg(str("\n--- TURN STARTED: ", team_name, " ---"))
	InGameTerminal.log_msg(str("Movement Points (Blue): ", blue_ap))
	InGameTerminal.log_msg(str("Cannons to fire: ", unfired_cannons))
	
	if unfired_cannons <= 0:
		InGameTerminal.log_msg(str(team_name, " has no cannons left! Turn skipped."))
		call_deferred("end_turn")

func register_cannon_fire() -> void:
	unfired_cannons -= 1
	InGameTerminal.log_msg(str("Cannon fired! Remaining for this turn: ", unfired_cannons))
	if unfired_cannons <= 0:
		end_turn()

func end_turn() -> void:
	if current_turn == TargetComponent.Team.BLUE:
		start_turn(TargetComponent.Team.RED)
	else:
		start_turn(TargetComponent.Team.BLUE)

func game_over(losing_team: TargetComponent.Team) -> void:
	var winner = "BLUE" if losing_team == TargetComponent.Team.RED else "RED"
	InGameTerminal.log_msg("\n*************************************")
	InGameTerminal.log_msg(str("GENERAL DEFEATED! ", winner, " WINS THE GAME!"))
	InGameTerminal.log_msg("*************************************\n")
	get_tree().paused = true 
