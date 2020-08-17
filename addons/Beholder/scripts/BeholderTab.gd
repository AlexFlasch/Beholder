tool
extends PanelContainer


# node references
onready var add_task_button := $UIContainer/AddTaskButtonContainer/AddTaskButton
onready var task_container := $UIContainer/TaskContainer
onready var file_dialog := $FileDialog
onready var add_task_form := preload("res://addons/Beholder/scenes/AddTaskForm.tscn")


# member variables
var tasks = []
var add_task_button_disabled := false setget set_add_task_button_disabled


# setters and getters
func set_add_task_button_disabled(disabled :bool) -> void:
	if add_task_button != null:
		add_task_button.disabled = disabled
	
	add_task_button_disabled = disabled


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_task_button.icon = get_icon('Add', 'EditorIcons')


func show_file_dialog(mode) -> void:
	file_dialog.mode = mode
	
	match mode:
		FileDialog.MODE_OPEN_DIR:
			file_dialog.window_title = 'Choose Directory to Watch'
		
		FileDialog.MODE_OPEN_FILE:
			file_dialog.window_title = 'Choose Script to Run'
	
	file_dialog.popup_centered()


func _on_add_task_button_up() -> void:
	var new_add_task_form = add_task_form.instance()
	task_container.add_child(new_add_task_form)
	
	new_add_task_form.connect('_on_task_created', self, '_on_add_task_form_submitted')
	new_add_task_form.connect('_on_task_cancelled', self, '_on_add_task_form_cancelled')
	
	set_add_task_button_disabled(true)


func _on_add_task_form_submitted() -> void:
	# handle serializing the user's tasks here
	set_add_task_button_disabled(false)


func _on_add_task_form_cancelled() -> void:
	set_add_task_button_disabled(false)
