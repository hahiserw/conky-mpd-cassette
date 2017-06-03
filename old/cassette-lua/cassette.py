import pygtk
pygtk.require('2.0')
import gtk
import cairo

import math
import gobject

class HelloWorld:
    alpha = 0

    def hello(self, widget, data=None):
        print 'Hello World'

    def delete_event(self, widget, event, data=None):
        print 'delete event occurred'
        return False

    def destroy(self, widget, data=None):
        print 'destroy signal occurred'
        gtk.main_quit()

    def __init__(self):
        self.window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        # self.window.set_position(gtk.WIN_POS_CENTER)

        self.window.set_title('cassette')
        self.window.resize(400, 400)

        self.window.set_app_paintable(True)

        self.screen = self.window.get_screen()
        colormap = self.screen.get_rgba_colormap()

        if colormap is not None and self.screen.is_composited():
            self.window.set_colormap(colormap)

        self.window.connect('delete_event', self.delete_event)
        self.window.connect('destroy', self.destroy)

        self.window.connect('expose-event', self.on_draw)
        self.window.show_all()

        self.timer = gobject.timeout_add (100, self.force_update)

    def force_update(self):
        self.on_draw(None, None)

        return True

    def on_draw(self, widget, event):
        print 'draw'

        # width, height = widget.get_size()

        if widget:
            cr = widget.window.cairo_create()
        else:
            cr = self.window.cairo_create()

        cr.set_operator(cairo.OPERATOR_CLEAR)
        cr.rectangle(10, 10, 380, 380)
        cr.fill()

        cr.set_operator(cairo.OPERATOR_OVER)
        cr.set_source_rgba(0.2, 0.2, 0.2, 0.4)
        # cr.arc(10, 10, 10, 0, 2 * pi)
        # cr.fill()

        x = 100
        y = 100
        outer_r = 30
        inner_r = 10
        size = 1

        self.alpha += 0.1

        for i in range(0, 6):
            p  = math.pi * i / 3
            x0 = x + math.cos(self.alpha + p) * (outer_r - 1 * size)
            y0 = y + math.sin(self.alpha + p) * (outer_r - 1 * size)
            x1 = x + math.cos(self.alpha + p) * inner_r
            y1 = y + math.sin(self.alpha + p) * inner_r

            cr.move_to(x0, y0)
            cr.line_to(x1, y1)
            cr.stroke()

    def main(self):
        gtk.main()

if __name__ == '__main__':
    hello = HelloWorld()
    hello.main()
