local cairo = require('cairo')

-- local lgi = require 'lgi'
-- local cairo = lgi.cairo


conky_window = {
	display  = 0,
	drawable = 1,
	visual   = 1,
	width    = 300,
	height   = 300,
}

-- local cs = cairo_xlib_surface_create(
-- 	conky_window.display,
-- 	conky_window.drawable,
-- 	conky_window.visual,
-- 	conky_window.width,
-- 	conky_window.height)


local cs = cairo.image_surface_create(cairo.FORMAT_RGB24, conky_window.width, conky_window.height)
local cr = cairo_create(cs)



cairo_set_line_width(cr, 3)
cairo_set_source_rgba(cr, 0.5, 0.5, 0.5, 0.5)

while true do
	cairo_move_to(cr, 5, 5)
	cairo_line_to(cr, 100, 100)
	cairo_stroke(cr)
end
