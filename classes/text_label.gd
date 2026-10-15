extends RichTextLabel
class_name WrapRichText

@export var max_pixel_width: float = 300.0

func update_wrapping(new_text: String):
	text = new_text
	# Check the size of the text with the current font
	var font = get_theme_font("normal_font")
	var font_size = get_theme_font_size("normal_font_size")
	var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	if text_width > max_pixel_width:
		autowrap_mode = TextServer.AUTOWRAP_WORD
		custom_minimum_size.x = max_pixel_width
	else:
		autowrap_mode = TextServer.AUTOWRAP_OFF
		custom_minimum_size.x = 0
