extends RichTextLabel
class_name WrapRichText

@export var max_pixel_width: float = 300.0

func update_wrapping(new_text: String):
	text = new_text
	autowrap_mode = TextServer.AUTOWRAP_WORD
	fit_content = true
