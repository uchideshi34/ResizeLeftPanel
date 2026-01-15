var script_class = "tool"

var _lib_mod_config = null
var timer = null
const WAIT_TIME = 0.5

var panel_min_size = Vector2.ZERO

# Logging Functions
const ENABLE_LOGGING = true
var logging_level = 0

#########################################################################################################
##
## UTILITY FUNCTIONS
##
#########################################################################################################

func outputlog(msg,level=0):
	if ENABLE_LOGGING:
		if level <= logging_level:
			printraw("(%d) <ResizeLeftPanel>: " % OS.get_ticks_msec())
			print(msg)
	else:
		pass

#########################################################################################################
##
## CORE FUNCTIONS
##
#########################################################################################################

func setup_resize_area(tool_type: String):

	outputlog("setup_resize_area: " + str(tool_type),2)

	var tool_panel = Global.Editor.Toolset.GetToolPanel(tool_type)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = 3
	hbox.size_flags_vertical = 3

	tool_panel.add_child(hbox)
	tool_panel.remove_child(tool_panel.Align)
	hbox.add_child(tool_panel.Align)

	var resize_vbox = VBoxContainer.new()
	resize_vbox.rect_min_size = Vector2(10,0)
	resize_vbox.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	resize_vbox.connect("gui_input", self, "on_panel_size_drag_management", [tool_panel])
	hbox.add_child(resize_vbox)

# Sets up the UI for our tree to live in
func setup_resize_areas():

	outputlog("setup_panel",2)

	for tool_type in Global.Editor.Toolset.ToolPanels.keys():
		setup_resize_area(tool_type)

# Function to respond when panel drag is active
func on_panel_size_drag_management(event: InputEvent, tool_panel):

	outputlog("on_panel_size_drag_management",3)

	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		var local_mouse_pos = tool_panel.get_local_mouse_position()
		if Global.Editor.content.rect_size.x > 60 || local_mouse_pos.x > 0.0:
			panel_min_size = Vector2(max(local_mouse_pos.x,0.0),0.0)
			tool_panel.Align.set_custom_minimum_size(panel_min_size)
			timer.start(WAIT_TIME)

# Function to update all panels
func update_all_panels():

	outputlog("update_all_panels",2)

	for tool_type in Global.Editor.Toolset.ToolPanels.keys():
		Global.Editor.Toolset.GetToolPanel(tool_type).Align.set_custom_minimum_size(panel_min_size)


#########################################################################################################
##
## _LIB CONFIG FUNCTIONS
##
#########################################################################################################

# Make Lib configs for logging
func make_lib_configs():

	var _lib_config_builder = Global.API.ModConfigApi.create_config()
	_lib_config_builder\
		.h_box_container().enter()\
			.label("Core Log Level ")\
			.option_button("core_log_level", 0, ["0","1","2","3","4"])\
		.exit()
	_lib_mod_config = _lib_config_builder.build()

	logging_level = int(_lib_mod_config.core_log_level)

#########################################################################################################
##
## VERSION CHECKER FUNCTIONS
##
#########################################################################################################

# Check whether a semver strng 2 is greater than string one. Only works on simple comparisons - DO NOT USE THIS FUNCTION OUTSIDE THIS CONTEXT
func compare_semver(semver1: String, semver2: String) -> bool:

	outputlog("compare_semver: semver1: " + str(semver1) + " semver2" + str(semver2),2)
	var semver1data = get_semver_data(semver1)
	var semver2data = get_semver_data(semver2)

	if semver1data == null || semver2data == null : return false

	if semver1data["major"] != semver2data["major"]:
		return semver1data["major"] < semver2data["major"]
	if semver1data["minor"] != semver2data["minor"]:
		return semver1data["minor"] < semver2data["minor"]
	if semver1data["patch"] != semver2data["patch"]:
		return semver1data["major"] < semver2data["major"]
	
	return false

# Parse the semver string
func get_semver_data(semver: String):

	var data = {}

	if semver.split(".").size() < 3: return null

	return {
		"major": int(semver.split(".")[0]),
		"minor": int(semver.split(".")[1]),
		"patch": int(semver.split(".")[2].split("-")[0])
	}


#########################################################################################################
##
## MAIN START FUNCTION
##
#########################################################################################################

# We only initialize things that stay constant through the life of the mod in start
func start():

	outputlog("Resize Left Panel Panel Mod has loaded.",0)

	# If _Lib is installed, store the visibility status of the layer panel
	if Engine.has_signal("_lib_register_mod"):
		# Register this mod with _lib
		Engine.emit_signal("_lib_register_mod", self)
		# Build a the lib configs
		make_lib_configs()
		var _lib_mod_meta = Global.API.ModRegistry.get_mod_info("CreepyCre._Lib").mod_meta
		if _lib_mod_meta != null:
			if compare_semver("1.1.2", _lib_mod_meta["version"]):
				var update_checker = Global.API.UpdateChecker
				
				update_checker.register(Global.API.UpdateChecker.builder()\
														.fetcher(update_checker.github_fetcher("uchideshi34", "ResizeLeftPanel"))\
														.downloader(update_checker.github_downloader("uchideshi34", "ResizeLeftPanel"))\
														.build())
	
	setup_resize_areas()

	timer = Timer.new()
	timer.one_shot = true
	timer.auto_start = false
	timer.wait_time = WAIT_TIME
	timer.connect("timeout", self, "update_all_panels")

	Global.World.add_child(timer)
