extends HBoxContainer


# export variables
export(String) var dir_path setget set_dir_path


# node references
onready var dir_path_label := $DirectoryPath
onready var edit_entry_button := $EditEntryButton
onready var validation_icon := $ValidationIconContainer/ValidationIcon
onready var dir_path_input := $DirectoryInput
onready var find_dir_button := $FindDirectoryButton
onready var submit_button := $SubmitEditButton
onready var cancel_button := $CancelEditButton


# member variables
var is_in_edit_mode := false
var is_valid := true setget set_is_valid
var dir_select_connected := false


# setters and getters
func set_dir_path(path :String) -> void:
	if dir_path_label != null:
		dir_path_label.text = path
	
	dir_path = path


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


# signals
signal _on_dir_entry_edited()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dir_path_label.text = dir_path if dir_path != null else ''
	
	edit_entry_button.icon = get_icon('Edit', 'EditorIcons')
	find_dir_button.icon = get_icon('Folder', 'EditorIcons')
	submit_button.icon = get_icon('Save', 'EditorIcons')
	cancel_button.icon = get_icon('Remove', 'EditorIcons')


func swap_modes() -> void:
	is_in_edit_mode = not is_in_edit_mode
	
	dir_path_label.visible = not is_in_edit_mode
	edit_entry_button.visible = not is_in_edit_mode
	dir_path_input.visible = is_in_edit_mode
	find_dir_button.visible = is_in_edit_mode
	submit_button.visible = is_in_edit_mode
	cancel_button.visible = is_in_edit_mode


# test to make sure the directory path can be opened
func validate_dir_path(path :String) -> void:
	var dir = Directory.new()
	var err = dir.open(path)
	
	set_is_valid(err == OK)


func _on_edit_entry_button_up() -> void:
	dir_path_label.visible = false
	
	swap_modes()


# open the FileDialog in directory mode, and connect to its dir_selected signal
func _on_find_directory_button_up() -> void:
	BeholderPlugin.main_scene.show_file_dialog(FileDialog.MODE_OPEN_DIR)
	
	if not dir_select_connected:
		BeholderPlugin.main_scene.file_dialog.connect('dir_selected', self, '_on_directory_selected')
		dir_select_connected = true


func _on_directory_selected(dir_path :String) -> void:
	dir_path_input.text = dir_path
	
	validate_dir_path(dir_path)
