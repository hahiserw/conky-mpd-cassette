local _draw_queue = {}

function _pop_draw_queue(t)
	for i = 0, t do
		table.remove(_draw_queue)
	end
end

local graphic_fns = {
	'arc',
}

for k, name in pairs(graphic_fns) do
	_G['cairo_' .. name] = function(...)
		table.insert(_draw_queue, {
			fn   = name,
			args = {...},
		})
	end
end


local noop_fns = {
	'save',
	'restore',
	'create',
	'destroy',
	'xlib_surface_create',
	'surface_destroy',
	-- temp
	'set_operator',
	'new_sub_path',
	'close_path',
}

for k, name in pairs(noop_fns) do
	_G['cairo_' .. name] = function()
	end
end


CAIRO_OPERATOR_CLEAR = nil


function _draw()
	local last_index = #_draw_queue
	if last_index == 0 then
		return
	end

	local last = _draw_queue[last_index]

	local args = last.args
	table.remove(args, 1) -- remove cr argument

	local fn = love.graphics[last.fn]

	-- damn lame
	if last.fn == 'line' then
		fn(unpack(args))
	else
		fn(last.method, unpack(args))
	end

	table.remove(_draw_queue)
end

function cairo_stroke()
	local last_index = #_draw_queue
	if last_index == 0 then
		return
	end

	_draw_queue[last_index].method = 'line'

	_draw()
end

function cairo_fill()
	local last_index = #_draw_queue
	if last_index == 0 then
		return
	end

	_draw_queue[last_index].method = 'fill'

	_draw()
end


local _draw_lines_queue = {}

function cairo_move_to(cr ,x, y)
	table.insert(_draw_queue, {
		fn   = 'line',
		args = {cr, x, y},
	})

	_draw_lines_queue = {x, y}
end

function cairo_line_to(cr ,x, y)
	local last_index = #_draw_queue
	if last_index == 0 then
		return
	end

	local args = _draw_queue[last_index].args

	table.insert(args, x)
	table.insert(args, y)
end

function cairo_set_line_width(cr, width)
	love.graphics.setLineWidth(width)
end

function cairo_set_source_rgba(cr, r, g, b, a)
	love.graphics.setColor(255 * r, 255 * g, 255 * b, 255 * a)
end
