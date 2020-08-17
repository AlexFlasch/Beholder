tool
extends VBoxContainer


# node references
onready var add_dir_button := $TaskContainer/VBoxContainer/DirectoryEntriesContainer/DirectoryWatchers/AddDirectoryButton
onready var add_script_button := $TaskContainer/VBoxContainer/ScriptEntriesContainer/ScriptRunnersContainer/AddScriptButton
onready var create_task_button := $TaskActionContainer/CreateTaskButton
onready var cancel_task_button := $TaskActionContainer/CancelTaskButton
onready var task_name := $TaskContainer/VBoxContainer/TaskNameContainer/TaskName
onready var task_name_validation_icon := $TaskContainer/VBoxContainer/TaskNameContainer/CenterContainer/NameValidationIcon
onready var watchers_container := $TaskContainer/VBoxContainer/DirectoryEntriesContainer/DirectoryWatchers
onready var runners_container := $TaskContainer/VBoxContainer/ScriptEntriesContainer/ScriptRunnersContainer
onready var add_dir_entry := preload("res://addons/Beholder/scenes/AddDirectoryEntry.tscn")
onready var add_script_entry := preload("res://addons/Beholder/scenes/AddScriptEntry.tscn")


# member variables
var task_name_is_valid := false setget set_task_name_is_valid
var form_is_valid := false setget set_form_is_valid
var validation_update_running := false


# setters and getters
func set_task_name_is_valid(valid :bool) -> void:
	if task_name_validation_icon != null:
		if valid:
			task_name_validation_icon.texture = null
			task_name_validation_icon.hint_tooltip = ''
		
		else:
			task_name_validation_icon.texture = get_icon('NodeWarning', 'EditorIcons')
			task_name_validation_icon.hint_tooltip = 'The tasks name must not be empty'
	
	task_name_is_valid = valid
	
	# update the whole form's validation status
	_on_validation_status_updated()


func set_form_is_valid(valid :bool) -> void:
	if create_task_button != null:
		if valid:
			create_task_button.disabled = false
			create_task_button.hint_tooltip = ''
		
		else:
			create_task_button.disabled = true
			create_task_button.hint_tooltip = 'It looks like there\'s a problem with the task. Hover any warning symbols to find out what\'s wrong.'
	
	form_is_valid = valid


# signals
signal _on_task_created()
signal _on_task_cancelled()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_dir_button.icon = get_icon('Add', 'EditorIcons')
	add_script_button.icon = get_icon('Add', 'EditorIcons')
	
	create_task_button.icon = get_icon('Save', 'EditorIcons')
	cancel_task_button.icon = get_icon('Remove', 'EditorIcons')
	
	set_task_name_is_valid(false)
	
	var initial_dir_entry = watchers_container.get_child(0) as AddDirectoryEntry
	initial_dir_entry.connect('_on_validation_changed', self, '_on_validation_status_updated')
	
	var initial_script_entry = runners_container.get_child(0) as AddScriptEntry
	initial_script_entry.connect('_on_validation_changed', self, '_on_validation_status_updated')


func _process(_delta) -> void:
	# disable removing the only directory watcher in the list
	# it will be the only watcher in the list if there's only one instance
	# of AddDirectoryEntry and the AddDirectoryButton
	if watchers_container == null or runners_container == null:
		return
	
	# update disabled remove button for directories
	if watchers_container.get_child_count() == 2:
		watchers_container.get_child(0).remove_disabled = true
	else:
		watchers_container.get_child(0).remove_disabled = false
		
	# update disabled remove button for scripts
	if runners_container.get_child_count() == 2:
		runners_container.get_child(0).remove_disabled = true
	else:
		runners_container.get_child(0).remove_disabled = false


# add new directory line in the task
func _on_add_dir_button_up() -> void:
	var new_entry = add_dir_entry.instance()
	new_entry.connect('_on_validation_changed', self, '_on_validation_status_updated')
	watchers_container.add_child(new_entry)
	watchers_container.move_child(new_entry, watchers_container.get_child_count() - 2)


# add new script line in the task
func _on_add_script_button_up() -> void:
	var new_entry = add_script_entry.instance()
	new_entry.connect('_on_validation_changed', self, '_on_validation_status_updated')
	runners_container.add_child(new_entry)
	runners_container.move_child(new_entry, runners_container.get_child_count() - 2)


# add the new task to the list of current tasks
func _on_create_task_button_up() -> void:
	var directories = []
	for dir_entry in watchers_container.get_children():
		directories.append(dir_entry.get_node('DirectoryInput').text)
	
	var scripts = []
	for script_entry in runners_container.get_children():
		scripts.append(script_entry.get_node('ScriptInput').text)
	
	var task_dict = {
		'name': task_name.text,
		'directories': directories,
		'scripts': scripts
	}
	
	BeholderPlugin.add_task(task_dict)
	emit_signal('_on_task_created')
	queue_free()


# cancel adding the new task
func _on_cancel_task_button_up() -> void:
	emit_signal('_on_task_cancelled')
	queue_free()


# check to make sure the task name is not empty
func _on_task_name_text_changed() -> void:
	set_task_name_is_valid(task_name.text != '')


# update the form's validation status whenever a child's is_valid value changes
func _on_validation_status_updated() -> void:
	# this callback could potentially be attempting to run multiple times simultaneously
	# make sure it only runs once per validation update.
	if validation_update_running:
		return
	
	validation_update_running = true
	
	var all_dirs_valid = true
	var dir_entries = watchers_container.get_child_count()
	
	# - 1 since the last child is a button
	for i in range(0, dir_entries - 1):
		var entry = watchers_container.get_child(i)
		if not entry.is_valid:
			all_dirs_valid = false
			break
	
	var all_scripts_valid = true
	var script_entries = runners_container.get_child_count()
	
	# - 1 since the last child is a button
	for i in range(0, script_entries - 1):
		var entry = watchers_container.get_child(i)
		if not entry.is_valid:
			all_scripts_valid = false
			break
	
	set_form_is_valid(all_dirs_valid and all_scripts_valid and task_name_is_valid)
	
	validation_update_running = false
