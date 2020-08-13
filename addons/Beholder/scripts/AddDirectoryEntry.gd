tool
extends GridContainer


# constants
const FILE_DIALOG_W := 1000
const FILE_DIALOG_H := 600


# export variables
export(int) var entry_position


# node references
onready var find_directory_button := $FindDirectoryButton
onready var remove_entry_button := $RemoveEntryButton
onready var file_dialog = $FileDialog


# member variables



# Called when the node enters the scene tree for the first time.
func _ready():
	find_directory_button.icon = get_icon('Folder', 'EditorIcons')
	remove_entry_button.icon = get_icon('Remove', 'EditorIcons')
	
	if entry_position == 0:
		remove_entry_button.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_find_directory_button_up():
	file_dialog.popup_centered_clamped(Vector2(FILE_DIALOG_W, FILE_DIALOG_H), 0.75)
