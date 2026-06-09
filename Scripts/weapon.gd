class_name Weapon extends Target

# Weapons get everything a Target has (Health, Teams, take_damage) PLUS weapon stats!
@export var max_power: float = 50.0 
@export var aim_speed: float = 2.0 
@export var projectile_scene: PackedScene

# You can also move your CannonState enum and action point variables in here later!
