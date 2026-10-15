extends Panel
class_name msg

var current_text: String = "This is a placeholder message. it is also very long This is a placeholder message. it is also very longThis is a placeholder message. it is also very longThis is a placeholder message. it is also very long"
var bbcode_effects
var user = "USER"
var time = Time.get_unix_time_from_system()

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Wait for container layout to settle
	await get_tree().process_frame
	
	# Dynamically get parent width, defaulting safely if unavailable
	var parent_width = 300.0
	if get_parent() is Control and get_parent().size.x > 0:
		parent_width = get_parent().size.x - 20 # 20px margin padding
		
	var usable_width = parent_width
	var text_width = usable_width - 20 # 10px padding on left and right
	
	custom_minimum_size = Vector2(usable_width, 50)
	position = Vector2.ZERO
	
	# 1. Setup the username and timestamp header
	var name_display = WrapRichText.new()
	name_display.bbcode_enabled = true
	name_display.position = Vector2(10, 5)
	name_display.custom_minimum_size = Vector2(text_width, 25)
	name_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_display.text = user + " [color=#808080]" + str(format_message_time(time)) + "[/color]"
	add_child(name_display)
	
	# 2. Setup the message body text node
	var text = WrapRichText.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.position = Vector2(10, 30)
	text.custom_minimum_size = Vector2(text_width, 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.update_wrapping(current_text)
	add_child(text)
	
	# 3. Dynamically resize the Panel height to fit the header + text + bottom padding
	await get_tree().process_frame
	var total_height = text.position.y + text.size.y + 15 # 15px bottom padding
	custom_minimum_size = Vector2(usable_width, max(50.0, total_height))

## Formats a message's unix timestamp relative to the current system time in local time.
func format_message_time(msg_unix_time: float) -> String:
	# Dynamically convert UTC unix time to local time using the system's timezone bias (in minutes)
	var local_unix_time = msg_unix_time + (Time.get_time_zone_from_system().bias * 60)
	
	# 1. Get the date/time dictionaries for both the message and now using local time
	var msg_dict = Time.get_datetime_dict_from_unix_time(local_unix_time)
	var now_dict = Time.get_datetime_dict_from_system(false) # false = local system time
	
	# 2. Convert 24-hour time to 12-hour format and determine AM/PM
	var period = "AM"
	var hour_12 = msg_dict.hour
	
	if hour_12 >= 12:
		period = "PM"
		if hour_12 > 12:
			hour_12 -= 12
	elif hour_12 == 0:
		hour_12 = 12
		
	# Format the minute string to always be two digits (e.g., "05" instead of "5")
	var minute_str = "%02d" % msg_dict.minute
	var time_str = "%d:%s %s" % [hour_12, minute_str, period]
	
	# 3. Check if it's the exact same calendar day (Same Year, Month, and Day)
	var is_same_day = (msg_dict.year == now_dict.year and 
					   msg_dict.month == now_dict.month and 
					   msg_dict.day == now_dict.day)
	
	if is_same_day:
		# Output format: "5:40 PM"
		return time_str
	else:
		# Get a readable month string using a match block
		var month_name = ""
		match msg_dict.month:
			1: month_name = "Jan"
			2: month_name = "Feb"
			3: month_name = "Mar"
			4: month_name = "Apr"
			5: month_name = "May"
			6: month_name = "Jun"
			7: month_name = "Jul"
			8: month_name = "Aug"
			9: month_name = "Sep"
			10: month_name = "Oct"
			11: month_name = "Nov"
			12: month_name = "Dec"
			
		# Output format: "Oct 15, 5:40 PM" (Includes year if it's a completely different year)
		if msg_dict.year != now_dict.year:
			return "%s %d, %d, %s" % [month_name, msg_dict.day, msg_dict.year, time_str]
		else:
			return "%s %d, %s" % [month_name, msg_dict.day, time_str]
