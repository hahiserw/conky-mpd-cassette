require('conky2love')
require('cassette')

-- https://love2d.org/forums/viewtopic.php?f=4&t=11158https://love2d.org/forums/viewtopic.php?f=4&t=11158https://love2d.org/forums/viewtopic.php?f=4&t=11158
-- local fw = love.filesystem.load("fileWatch.lua")()

interval = 0
-- just don't draw it
function rectangle_with_rounded_edges()
end

-- function playlist_duration()
-- 	local file = io.popen('~/bin/mpd-album-duration once')
-- 	-- local file = io.open('/rtmp/cassette')
-- 	if not file then
-- 		return
-- 	end
--
-- 	local contents = file:read('*all')
-- 	local playlist_position, playlist_duration, playlist_state =
-- 		string.match(contents, '(%d+%.*%d*) (%d+%.*%d*) (%S+)')
--
-- 	playlist_position = tonumber(playlist_position) or 0
-- 	playlist_duration = tonumber(playlist_duration) or 0
--
-- 	file:close()
--
-- 	print(playlist_duration, playlist_position, playlist_state)
--
-- 	return playlist_duration, playlist_position, playlist_state
-- end

updates      = 0
conky_window = {}
conky_info   = {}

function conky_parse(name)
	if name == '$updates' then
		return updates
	end
end

function love.load(arg)
	conky_window.width  = love.graphics.getWidth()
	conky_window.height = love.graphics.getHeight()

	conky_init()
end

function love.update(dt)
	if love.keyboard.isDown('q') then
		love.event.quit()
	end

	updates = updates + 1

	conky_info.update_interval = dt
end

function love.draw(dt)
	conky_render()
end
