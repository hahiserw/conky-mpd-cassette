# Cassette

Animated cassette in conky that shows current mpd's playlist status


# Story

![wallpaper sample](https://raw.githubusercontent.com/hahiserw/conky-mpd-cassette/master/wallpaper-sample.png)

I once saw this wallpaper and I thought it would be cool to see it animated
with reels spining and changing size according to progress of current playing
music. I was using conky and I thought: why not do it in conky? And I did, it
was about 2 years ago. I had also tried "porting" it to love (2d lua
framework), because I thought it could run with lower cpu usage, but there was
no transparent background, so it wouldn't look as cool (maybe one could just
set a background and draw cassette over it, but for some reason I just wanted
transparent background). I also thought about writing Xorg program that would
only display this cassette - that would be fast, but as time passed I forgot
about this project. I'm uploading this because it might inspire someone.


## Installation

0. Install Python MPD client library for python 2
1. Put bin/mpd-album-duration into bin directory in your home directory
2. Put .conkyrc and .conky into your home directory
3. Modify .conkyrc and .conky/cassette.lua settings according to your needs
4. Run `conky -c ~/.conkyrc`


## How it works

conky draws the cassette systematically calling (about every second)
bin/mpd-album-duration script to get current position and duration of entire
mpd playlist.


## Notes
Only reels and 2 pieces of tape changes, so it might be changed to draw some
image and mentioned parts above it. I was guessing reels spinning speed and
few other things, but it looks pretty accurate. For more info check
.conky/cassette.lua


## TODO?

* Show current playing song as a label
* Rewrite as a standalone program
* Fix reels animation to make it more smooth
