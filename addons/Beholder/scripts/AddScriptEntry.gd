tool
extends GridContainer
class_name AddScriptEntry


# export variables
export(bool) var remove_disabled = false setget set_remove_disabled


# node references
onready var script_input = $ScriptInput
onready var validation_icon = $CenterContainer/ValidationStatus
onready var find_script_button = $FindScriptButton
onready var remove_entry_button = $RemoveEntryButton


# member variables
var file_select_connected := false
var is_valid := false setget set_is_valid


# setters and getters
func set_remove_disabled(val :bool) -> void:
	if remove_entry_button != null:
		remove_entry_button.disabled = val
	
	remove_disabled = val


func set_is_valid(valid :bool, validation_text :String = '') -> void:
	if valid:
		validation_icon.texture = null
		validation_icon.hint_tooltip = ''
	
	else:
		validation_icon.texture = get_icon('NodeWarning', 'EditorIcons')
		validation_icon.hint_tooltip = (
			'All task scripts must extend EditorScript, and have a _run method.'
			if validation_text == '' else validation_text
		)
	
	is_valid = valid
	emit_signal('_on_validation_changed')


# signals
signal _on_validation_changed()


# Called when the node enters the scene tree for the first time.
func _ready():
	find_script_button.icon = get_icon('Folder', 'EditorIcons')
	remove_entry_button.icon = get_icon('Remove', 'EditorIcons')
	
	set_is_valid(false, 'Please select an EditorScript to run.')


func validate_script(script_path :String) -> void:
	if script_path == '':
		set_is_valid(false, 'Please select an EditorScript to run.')
		return
	
	# make sure the file exists first, before we try to load it
	var file = File.new()
	var err = file.open(script_path, File.READ)
	
	if err != OK:
		set_is_valid(false, 'Unable to find script file. Please try selecting it again.')
		return
	
	var script = load(script_path).new()
	set_is_valid(script.is_class('EditorScript') and script.has_method('_run'))


func _on_find_script_button_up() -> void:
	BeholderPlugin.main_scene.show_file_dialog(FileDialog.MODE_OPEN_FILE)
	
	if not file_select_connected:
		BeholderPlugin.main_scene.file_dialog.connect('file_selected', self, '_on_file_selected')
		file_select_connected = true


func _on_file_selected(path :String) -> void:
	script_input.text = path
	
	validate_script(path)


func _on_remove_entry_button_up() -> void:
	self.queue_free()


func _on_script_input_text_changed():
	validate_script(script_input.text)
