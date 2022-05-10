using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;


class MyMenu2InputDelegate extends WatchUi.Menu2InputDelegate {

    hidden var _view;

    function initialize() {
        System.println("initialize SkatingMenu2Delegate");
        Menu2InputDelegate.initialize();
        _view = Application.getApp().skatingView;
    }

    function onSelect(item) {
        System.println(item.isEnabled() == true);
        if (item.isEnabled() == true) {
                _view.foregroundColor = Gfx.COLOR_WHITE;
                _view.backgroundColor = Gfx.COLOR_BLACK;
                item.setEnabled(true);
            } else {
                _view.foregroundColor = Gfx.COLOR_BLACK;
                _view.backgroundColor = Gfx.COLOR_WHITE;
                item.setEnabled(false);
            }
    }
}