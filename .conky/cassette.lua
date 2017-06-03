require('cairo')


local settings = {
	seconds_per_reel = 60 * 60,
	duration = 50,
	size = 2, -- XXX compute somehow
	position = { -- XXX compute somehow (minimum_size - gap_{x,y}) - center
	-- auto = true
		x = 620, y = 420,
	},
	colors = {
		fg   = {0.8,  0.8,  0.8,  0.8},
		bg   = {0.6,  0.6,  0.6,  0.3},
		tape = {0.35, 0.35, 0.35, 0.9},
	},
	-- auto_progress_update = true,
}


-- {{{ t: current time, b: start value, c: change in value, d: duration
-- http://gizma.com/easing/
-- function linear_tween(t, b, c, d)
-- 	return c * t / d + b
-- end
--
-- function ease_out_quad(t, b, c, d)
-- 	t = t / d
-- 	return -c * t * (t - 2) + b
-- end
--
-- function ease_in_out_quadratic(t, b, c, d)
-- 	t = t / (d / 2)
--
-- 	if t < 1 then
-- 		return c / 2 * math.pow(t, 2) + b
-- 	end
--
-- 	t = t - 1
--
-- 	return -c / 2 * (t * (t - 2) - 1) + b
-- end
--
-- function ease_in_out_cubic(t, b, c, d)
-- 	t = t / (d / 2)
--
-- 	if t < 1 then
-- 		return c / 2 * math.pow(t, 3) + b
-- 	end
--
-- 	t = t - 2
--
-- 	return c / 2 * (math.pow(t, 3) + 2) + b
-- end
-- }}}


local function setup_methods(instance, base) -- {{{ add it to {}?
	for k, v in pairs(base) do
		if type(v) == 'function' then
			instance[k] = v
		end
	end
end
-- }}}


local reel = {} -- {{{

function reel:new(cassette, settings, mode, x, y)
	local instance = {}

	setup_methods(instance, self)

	instance.cassette = cassette
	instance.settings = settings

	instance.progress = mode == 1 and 1 or 0
	instance.alpha    = 0
	instance.rolls    = 0

	instance.x    = x
	instance.y    = y
	instance.mode = mode -- mode == 1? supply reel: takeup reel

	return instance
end

function reel:angle()
	local m = -1
	if self.mode == 1 then
		m = 1
	end

	-- XXX Get it right
	local a_acc = (1 - self.progress)

	local mai = 5
	local per = 10
	local p = (per-mai)/per + mai * a_acc / per
	-- local p = 0.4 + a_acc * 0.6

	if self.cassette.playing then
		-- what's that?
		local step = - interval * 3 * p;

		-- To make it not exceed maximum value - is it necessary?
		if self.alpha <= - 2 * math.pi then
			self.alpha = self.alpha + 2 * math.pi
		end

		self.alpha = self.alpha + step
	end
end

function reel:update()
	local cassette_progress = self.cassette.progress

	if self.mode == 1 then
		self.progress = 1 - cassette_progress
	else
		self.progress = cassette_progress
	end

	local seconds_woundup = self.settings.duration * self.progress

	if settings.seconds_per_reel > 0 then
		self.rolls = 1 + 55 * seconds_woundup / settings.seconds_per_reel
	end


	self:angle()
end


function reel:draw(cr)
	local size = self.settings.size
	local colors = self.settings.colors

	local outer_r = 20 * size
	local inner_r = 14 * size

	local reel_start = 10 * size

	local r0 = reel_start + outer_r
	local r1 = reel_start + outer_r + self.rolls * 2 * size

	-- XXX where to put save and restore calls?
	cairo_save(cr)

	cairo_set_line_width(cr, 1 * size)

	cairo_save(cr)
	cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR)
	cairo_arc(cr, self.x, self.y, outer_r, 0, math.pi * 2)
	cairo_fill(cr)
	cairo_restore(cr)

	cairo_set_source_rgba(cr, unpack(colors.tape))

	cairo_set_line_width(cr, r1 - r0)
	cairo_arc(cr, self.x, self.y, (r1 + r0) / 2, 0, math.pi * 2)
	cairo_stroke(cr)


	cairo_set_source_rgba(cr, unpack(colors.fg))

	cairo_set_line_width(cr, 4 * size)

	for i = 0, 5 do
		local p  = math.pi * i / 3
		local x0 = self.x + math.cos(self.alpha + p) * (outer_r - 1 * size)
		local y0 = self.y + math.sin(self.alpha + p) * (outer_r - 1 * size)
		local x1 = self.x + math.cos(self.alpha + p) * inner_r
		local y1 = self.y + math.sin(self.alpha + p) * inner_r

		cairo_move_to(cr, x0, y0)
		cairo_line_to(cr, x1, y1)
		cairo_stroke(cr)
	end

	cairo_set_line_width(cr, 2 * size)
	cairo_arc(cr, self.x, self.y, outer_r, 0, math.pi * 2)
	cairo_stroke(cr)

	-- draw several circles
	-- cairo_set_line_width (cr, 2)
	-- for i = 1, rolls do
	-- 	local r = reel_start + outer_r + i * 3
	-- 	cairo_arc(cr, self.x, self.y, r, 0, math.pi * 2)
	-- 	cairo_stroke(cr)
	-- end

	cairo_restore(cr)
end


setmetatable(reel, {__call = function(...)
	return reel.new(...)
end})
-- }}}

local cassette = {} -- {{{

function cassette:new(settings)
	local instance = {}

	setup_methods(instance, self)

	instance.settings = settings

	local x0   = settings.position.x
	local y0   = settings.position.y
	local size = settings.size

	instance.playing  = false
	instance.progress = 0
	instance.duration = settings.duration

	instance.reels = {
		reel(instance, settings, 1, x0 - 78 * size, y0 - 12 * size),
		reel(instance, settings, 0, x0 + 78 * size, y0 - 12 * size),
	}

	return instance
end


function cassette:update(seconds_passed)
	if seconds_passed < self.settings.duration then
		self.progress = seconds_passed / self.settings.duration
	else
		self.progress = 1
	end

	self.reels[1]:update()
	self.reels[2]:update()
end

function cassette:set_state(state)
	if     state == 'play' then
		self.playing = true
	-- elseif state == 'pause' then
	-- 	self.playing = false
	-- elseif state == 'stop' then
	-- 	self.playing = false
	else
		self.playing = false
	end
end

function cassette:play()
	self.playing = true
end

function cassette:pause()
	self.playing = false
end

function reel_tangent(xp, yp, xs, ys, r, s) -- {{{
	local dx = xs - xp
	local dy = ys - yp
	local dd = math.sqrt(dx * dx + dy * dy)

	local a = math.asin(r / dd)
	local b = math.atan2(dy, dx)
	local t = b - s * a

	local x = xs + r * s *  math.sin(t)
	local y = ys + r * s * -math.cos(t)

	return x, y
end
-- }}}

local function cassette_draw_parts_half(self, cr, side)
	local x0             = self.settings.position.x
	local y0             = self.settings.position.y
	local size           = self.settings.size
	local tape_thickness = size * 1.4;

	-- local ri = side < 0 and 1 or 2
	local ri = (side + 3) / 2 -- faster? :)


	-- XXX r = r0 + rolls * 2 * size
	local r = 10 * size + 20 * size + self.reels[ri].rolls * 2 * size - tape_thickness / 2

	local xs, ys = self.reels[ri].x, self.reels[ri].y
	local xp, yp = x0 + side * 165 * size, y0 + 90 * size
	local lx, ly = reel_tangent(xp, yp, xs, ys, r, -1 * side)

	local bigger_thingy_x, bigger_thingy_y   = x0 + side * 155 * size, y0 + 105 * size
	local smaller_thingy_x, smaller_thingy_y = xp - side * (tape_thickness + 1.5), yp

	local main_tape_x = x0
	local main_tape_y = bigger_thingy_y + size * 5.5


	cairo_save(cr)

	cairo_set_line_width(cr, tape_thickness)
	cairo_set_source_rgba(cr, unpack(self.settings.colors.tape))


	-- tape from the reel to smaller thingy
	cairo_move_to(cr, xp, yp)
	cairo_line_to(cr, lx, ly)
	cairo_stroke(cr)

	-- tape from bigger thingy to smaller thingy
	cairo_move_to(cr, bigger_thingy_x + size * side * 4.8 + (side * tape_thickness / 2), bigger_thingy_y + size * 2)
	cairo_line_to(cr, smaller_thingy_x + size * side * 2, smaller_thingy_y)
	cairo_stroke(cr)

	-- piece of the tape on the bigger thingy
	local phase    = side * (ri - 2) * math.pi / 2
	local from, to = phase, math.pi / 2 + phase
	cairo_arc(cr, bigger_thingy_x, bigger_thingy_y, 5 * size + tape_thickness / 2, from, to)
	cairo_stroke(cr)

	-- piece of the tape on the smaller thingy
	local phase    = side * (ri - 2) * math.pi
	local from, to = - math.pi / 4 + phase, math.pi / 4 + phase
	cairo_arc(cr, smaller_thingy_x, smaller_thingy_y, 1.5 * size + tape_thickness / 2, from, to)
	cairo_stroke(cr)

	-- tape at the bottom
	cairo_move_to(cr, bigger_thingy_x, main_tape_y)
	cairo_line_to(cr, main_tape_x, main_tape_y)
	cairo_stroke(cr)

	cairo_restore(cr)


	cairo_save(cr)

	cairo_set_source_rgba(cr, unpack(self.settings.colors.fg))

	-- smaller thingy
	cairo_arc(cr, smaller_thingy_x, smaller_thingy_y, 1.5 * size, 0, math.pi * 2)
	cairo_fill(cr)

	-- bigger thingy
	cairo_arc(cr, bigger_thingy_x, bigger_thingy_y, 5 * size, 0, math.pi * 2)
	cairo_fill(cr)

	cairo_restore(cr)
end

function cassette:draw(cr)
	local x0   = self.settings.position.x
	local y0   = self.settings.position.y
	local size = self.settings.size

	local _top    = y0 - 115 * size
	local _bottom = y0 + 115 * size
	local _left   = x0 - 175 * size


	cairo_save(cr)

	cairo_set_line_width(cr, 2 * self.settings.size)

	-- filling
	cairo_set_source_rgba(cr, unpack(self.settings.colors.bg))
	rectangle_with_rounded_edges(cr, _left, _top, 350 * size, 230 * size, 7 * size)
	cairo_fill(cr)


	-- border
	cairo_set_source_rgba(cr, unpack(self.settings.colors.fg))
	rectangle_with_rounded_edges(cr, _left, _top, 350 * size, 230 * size, 7 * size)
	cairo_stroke(cr)


	-- reels
	self.reels[1]:draw(cr)
	self.reels[2]:draw(cr)


	-- tape
	cassette_draw_parts_half(self, cr, 1)
	cassette_draw_parts_half(self, cr, -1)


	-- this thing where the head comes in
	cairo_move_to(cr, x0 - 145 * size, _bottom)
	cairo_line_to(cr, x0 - 140 * size, y0 + 80 * size)
	cairo_line_to(cr, x0 + 140 * size, y0 + 80 * size)
	cairo_line_to(cr, x0 + 145 * size, _bottom)
	cairo_stroke(cr)


	-- border around reels
	rectangle_with_rounded_edges(cr, x0 - 103 * size, y0 - 37 * size, 206 * size, 50 * size, 25 * size, 4 * size)
	cairo_stroke(cr)

	cairo_restore(cr)
end

-- Apple's rectangle with rounded edges
-- Created by Helton Moraes (heltonbiker at gmail dot com). Uses round arcs and
-- takes advantage of the segment-creation property of cairo.arc() - just draw
-- the arcs, no need to draw straight segments in between.
function rectangle_with_rounded_edges(cr, x, y, width, height, r)
	local degrees = math.pi / 180

	cairo_new_sub_path(cr);
	cairo_arc(cr, x + width - r, y + r, r, -90 * degrees, 0 * degrees);
	cairo_arc(cr, x + width - r, y + height - r, r, 0 * degrees, 90 * degrees);
	cairo_arc(cr, x + r, y + height - r, r, 90 * degrees, 180 * degrees);
	cairo_arc(cr, x + r, y + r, r, 180 * degrees, 270 * degrees);
	cairo_close_path(cr);
end

setmetatable(cassette, {__call = function(...)
	return cassette.new(...)
end})
-- }}}



local c
function conky_init()
	c = cassette(settings)

	-- c_duration, c_progress, c_state = playlist_duration()

	-- settings.duration         = c_duration
	-- settings.seconds_per_reel = c_duration * 2

	-- c:set_state(c_state)
	-- c:update(c_progress)


	-- whoa
	-- conky_render() -- lame
end

-- local sync_interval = 5
local sync_interval = 1

local c_duration, c_progress = 0, 0
local c_progress_last = 0

seconds_passed = 0

function playlist_duration()
	local file = io.popen('~/bin/mpd-album-duration once')
	-- local file = io.open('/rtmp/cassette')
	if not file then
		return
	end

	local contents = file:read('*all')
	local playlist_position, playlist_duration, playlist_state =
		string.match(contents, '(%d+%.*%d*) (%d+%.*%d*) (%S+)')

	playlist_position = tonumber(playlist_position) or 0
	playlist_duration = tonumber(playlist_duration) or 0

	file:close()

	-- print(playlist_duration, playlist_position, playlist_state)

	return playlist_duration, playlist_position, playlist_state
end

-- XXX pierwsze wywołanie przed pętlą powinno być by nie czekać sync_interval na załadowanie wielkości rolek
-- don't wait sync_interval after conky run to update reels size
-- c_duration, c_progress = playlist_duration()

local window_loaded = false

function window_loaded_callback(data)
	print(data.height, data.width)
end

local last_second = 0

function conky_render()
	if not conky_window then
		return
	end

	if not window_loaded then
		if conky_window.width > 0 then
			window_loaded_callback(conky_window)
			window_loaded = true
		end
	end

	local cs = cairo_xlib_surface_create(
		conky_window.display,
		conky_window.drawable,
		conky_window.visual,
		conky_window.width,
		conky_window.height)

	local cr = cairo_create(cs)

	local updates  = tonumber(conky_parse('$updates'))
	local info     = conky_info
	-- local interval = info.update_interval
	interval = info.update_interval

	seconds_passed = interval * updates

	-- local interval_step = math.floor(seconds_passed) % sync_interval
	local interval_step = seconds_passed % sync_interval
	local seconds_passed_i = math.floor(seconds_passed)


	local update_time = last_second ~= seconds_passed_i and seconds_passed_i % sync_interval == 0

	last_second = seconds_passed_i

	-- io.write((seconds_passed_i % sync_interval), updates, '\r')

	if update_time then
	-- if false then
		c_progress_last = c_progress

		-- print('update')
		c_duration, c_progress, c_state = playlist_duration()

		settings.duration         = c_duration
		settings.seconds_per_reel = c_duration * 2
	end

	local real_progress = c_progress + interval_step

	-- if c_progress ~= c_progress_last then
	-- 	-- real_progress = real_progress - interval_step
	-- 	-- print('lol')
	-- 	-- print(c_progress, c_progress_last)
	-- end

	c:set_state(c_state)


	-- c:update(seconds_passed)
	-- c:update(seconds_passed + c_progress)
	c:update(real_progress)
	c:draw(cr)

	cairo_destroy(cr)
	cairo_surface_destroy(cs)
	cs = nil
	cr = nil
end
