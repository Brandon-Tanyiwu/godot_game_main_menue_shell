extends State
class_name Death


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func enter(_params: Dictionary = {}) -> void:
	if context:
		context.animatecontroller.play("Death")
	SignalManager.unit_death.emit(context)
	print("unit death,unit info:" ,context)
	

func exit() -> void:
	context.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_update(delta: float) -> void:
	if not context.animatecontroller.is_playing():
		exit()
