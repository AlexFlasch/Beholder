################################################################################
# Beholder: Simple watcher plugin                                              #
################################################################################
#                                                                              #
# ABOUT:                                                                       #
#   If you specify the directories you'd like watched, and the scripts you'd   #
#   like to be run, this plugin will run those EditorScripts any time file     #
#   names or file contents have changed, as well as when files are added or    #
#   removed in the specified subdirectories.                                   #
#                                                                              #
#------------------------------------------------------------------------------#
#                                                                              #
# POSSIBLE IMPROVEMENTS / TODOS:                                               #
#  * Allow some sort of system to allow some scripts to be run only when a     #
#      specific subdirectory is changed, rather than running all scripts when  #
#      any subdirectory has changed                                            #
#                                                                              #
#  * Add an in-editor UI to allow users to specify watched directories and     #
#      runner scripts more easily.                                             #
#                                                                              #
#------------------------------------------------------------------------------#
#                                                                              #
# LIMITATIONS / NOTICES:                                                       #
#  * This plugin only supports running EditorScripts. The script must extend   #
#      EditorScript and specify a _run() function inside of it.                #
#                                                                              #
#  * The `filesystem_changed` signal seems to fire multiple times per file     #
#      change. I'm unsure if this is a quirk of Godot, or just how I've made   #
#      the script for this plugin. Further investigation is required.          #
#                                                                              #
#  * This plugin has not been tested with any languages other than GDScript.   #
#      It may work with C# and other language bindings for Godot, but only if  #
#      that language's bindings support creating EditorScripts.                #
#                                                                              #
################################################################################

tool
extends EditorPlugin

var directories_to_watch := []
var scripts_to_run := []
const beholder_tab_scene := preload('res://addons/Beholder/scenes/BeholderTab.tscn')


# member variables
var tasks := []
var watch_dict := {}
var fs = get_editor_interface().get_resource_filesystem()
var main_scene


func _enter_tree():
	main_scene = beholder_tab_scene.instance()
	get_editor_interface().get_editor_viewport().add_child(main_scene)
	
	make_visible(false)
	
	# connect to the Godot Editor's internal filestystem so that we receive
	# a signal anytime Godot detects that the filesystem has changed
	fs.connect('filesystem_changed', self, '_on_fs_update')


func _exit_tree():
	if main_scene:
		main_scene.queue_free()


func has_main_screen():
	return true


func make_visible(visible):
	if main_scene:
		main_scene.visible = visible


func get_plugin_name():
	return 'Beholder'


func get_plugin_icon():
	return load('res://addons/Beholder/assets/Beholder_icon.svg')


# runs through all files/directories in the current directory
# if it encounters a directory, it will recursively call this function
# with the path parameter pointing to the directory it encountered.
# if it hits a file, it will get the md5 checksum of the file, and put
# the path and filename of the file as the key, and the md5 checksum as that
# entry's value into watch_dict
func build_watch_dict_helper(path :String = '') -> void:
	var dir = Directory.new()
	var err = dir.open(path)
	
	if err != OK:
		print('watcher_runner: error opening: %s' % path)
	
	dir.list_dir_begin(true)
	var file_name = dir.get_next()
	
	while file_name != '':
		if dir.current_is_dir():
			build_watch_dict_helper('%s/%s' % [path, file_name])
		
		else:
			var file = File.new()
			var file_md5 = file.get_md5('%s/%s' % [path, file_name])
			watch_dict['%s/%s' % [path, file_name]] = file_md5
		
		file_name = dir.get_next()


# this function kicks off building the watch_dict
# watch_dict is a dictionary with the paths and filenames of all files in
# the specified directories as the keys, and their md5 hash as the value
#
# i.e.
#
# watch_dict = {
#   "res://my_directory/my_file.tres": "551c076e3124468533dfc47d731a4383",
#   "res://my_directory/my_subdir/my_other_file.gd": "670a1f2019aa017f41a6eae44b06c311"
# }
func build_watch_dict() -> void:
	for path in directories_to_watch:
		build_watch_dict_helper(path)


# Runs whenever the Godot Editor has detected a change in the file system.
# This seems to actually get called multiple times per file change for some reason,
# so at the moment it will build the watch_dict each of the times it is called.
# However, since we're only watching for specified subdirectories we check to see
# if any of the files in our watched subdirectories have changed, and the runner scripts
# will only actually be kicked off once per file change.
#
# This is done by: firstly, checking if the amount of files have changed since last time.
# If they're the same, then we check if the file names have changed.
# Lastly, we then check if any of the md5 checksums have changed.
# If any of those 3 things have changed, run the specified EditorScripts
func _on_fs_update() -> void:
	print('filesystem changed, checking watched directories...')
	var prev_watch_dict := watch_dict.duplicate()
	build_watch_dict()
	
	var changed := false
	
	# compare both watch_dicts to see if files we're interested in have changed
	if prev_watch_dict.keys().size() != watch_dict.keys().size():
		changed = true
	
	if not changed:
		# check to see if keys changed first
		var prev_keys = prev_watch_dict.keys()
		var curr_keys = watch_dict.keys()
		for i in range(0, curr_keys.size()):
			if prev_keys[i] != curr_keys[i]:
				changed = true
				break
	
	if not changed:
		# check to see if file contents changed next
		var prev_vals = prev_watch_dict.values()
		var curr_vals = watch_dict.values()
		
		for i in range(0, curr_vals.size()):
			if prev_vals[i] != curr_vals[i]:
				changed = true
				break

	if changed:
		print('running scripts!')
		for script_path in scripts_to_run:
			var script :EditorScript = load(script_path).new()
			script._run()
		
		print('scripts finished.')


func add_task(task_dict :Dictionary) -> void:
	tasks.append(task_dict)


func remove_task(task_dict :Dictionary) -> void:
	var index = tasks.find(task_dict)
	
	if index == -1:
		print('[ERR] Beholder: unable to find task to remove.')
		return
	
	tasks.remove(index)


func edit_task(task_index :int, task_dict :Dictionary) -> void:
	if task_index < 0 or task_index > tasks.size() - 1:
		print('[ERR] Beholder: attempted to edit non-existent task.')
		return
	
	tasks[task_index] = task_dict
