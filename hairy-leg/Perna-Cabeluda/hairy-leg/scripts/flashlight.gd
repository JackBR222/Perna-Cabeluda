extends SpotLight3D

# Referência ao sprite glow que vai substituir a luz fraca
@onready var foot_glow = $"../FootGlow"  # Sprite3D filho do player

var is_on = true
var original_energy = 4.0

func _ready():
	# Guarda a energia original da lanterna
	original_energy = light_energy
	
	# Começa com o glow visível (lanterna desligada)
	foot_glow.visible = false


func _input(event):
	if event.is_action_pressed("flashlight_toggle"):
		# Alterna estado da lanterna
		is_on = !is_on
		
		if is_on:
			# Liga a lanterna principal
			light_energy = original_energy
			light_volumetric_fog_energy = 3.0
			
			# Esconde o glow dos pés
			foot_glow.visible = false
		else:
			# Desliga a lanterna
			light_energy = 0.0
			light_volumetric_fog_energy = 0.0
			
			# Mostra o glow dos pés
			foot_glow.visible = true
