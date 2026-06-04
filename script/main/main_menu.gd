extends Control

@onready var save_list = $SaveListContainer

func _ready() -> void:
	load_save_list()
	

func load_save_list():
	var saves = SaveManager.get_all_save()
	
	for save_file in saves:
		
		var button = Button.new()
		button.text = save_file
		save_list.add_child(button)
		button.pressed.connect(
			func():
				start_game(save_file)
		)
		

func start_game(save_file:String):
	SaveManager.load_game(save_file)
	SceneManager.change_scene(
		"res://scenes/hub/HubScene.tscn"
	)
	save_list.hide()
	
func _on_new_game_button_pressed():
	SaveManager.create_new_save("Player")
	SceneManager.change_scene(
		"res://scenes/hub/HubScene.tscn"
	)
	save_list.hide()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
