tool
extends PanelContainer


# node references
onready var add_task_button = $UIContainer/AddTaskContainer/AddTaskButton


# member variables
var tasks = []


# Called when the node enters the scene tree for the first time.
func _ready():
	add_task_button.icon = get_icon('Add', 'EditorIcons')
	print('add_task_button icon: ', str(add_task_button.icon))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_add_task_button_up():
	print('hello')
