tool
extends GridContainer
class_name AddDirectoryEntry


# constants
const FILE_DIALOG_W := 1000
const FILE_DIALOG_H := 600


# export variables
export(bool) var remove_disabled setget set_remove_disabled


# node references
onready var directory_input := $DirectoryInput
onready var find_directory_button := $FindDirectoryButton
onready var remove_entry_button := $RemoveEntryButton
onready var validation_icon := $IconContainer/ValidationIcon


# member variables
var dir_select_connected := false
var is_valid := false setget set_is_valid


# setters and getters
func set_remove_disabled(is_disabled :bool) -> void:
	if remove_entry_button != null:
		remove_entry_button.disabled = is_disabled
	
	remove_disabled = is_disabled


func set_is_valid(valid :bool, validation_text :String = '') -> void:
	if validation_icon != null:
		if valid:
			validation_icon.texture = null
			validation_icon.hint_tooltip = ''
			
		else:
			validation_icon.texture = get_icon('NodeWarning', 'EditorIcons')
			validation_icon.hint_tooltip = (
				'There was a problem accessing this directory. Please try selecting the directory again.'
				if validation_text == '' else validation_text
			)
	
	is_valid = valid
	
	emit_signal('_on_validation_changed')


# signals
signal _on_validation_changed()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	find_directory_button.icon = get_icon('Folder', 'EditorIcons')
	remove_entry_button.icon = get_icon('Remove', 'EditorIcons')
	
	set_is_valid(false, 'Please select a directory to watch.')

# test to make sure the directory path can be opened
func validate_dir_path(path :String) -> void:
	var dir = Directory.new()
	var err = dir.open(path)
	
	set_is_valid(err == OK)


# open the FileDialog in directory mode, and connect to its dir_selected signal
func _on_find_directory_button_up() -> void:
	print('In AddDirectoryEntry: BeholderPlugin.main_scene', str(BeholderPlugin.main_scene))
	BeholderPlugin.main_scene.show_file_dialog(FileDialog.MODE_OPEN_DIR)
	
	if not dir_select_connected:
		BeholderPlugin.main_scene.file_dialog.connect('dir_selected', self, '_on_directory_selected')
		dir_select_connected = true


# run when the FileDialog emits the dir_selected signal
func _on_directory_selected(dir_path :String) -> void:
	directory_input.text = dir_path
	
	validate_dir_path(dir_path)


# remove this directory entry in the UI
func _on_remove_entry_button_up():
	self.queue_free()


# run when the text inside the directory input changes in case the user
# is manually entering the directory path
func _on_directory_input_text_changed():
	if directory_input.text == '':
		set_is_valid(false, 'Please select a directory to watch.')
	
	validate_dir_path(directory_input.text)
