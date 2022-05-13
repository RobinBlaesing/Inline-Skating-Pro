using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;


class Menu2Delegate extends WatchUi.Menu2InputDelegate {

    hidden var _view;
    hidden var _controller;
    hidden var _fitManager;

    function initialize() {
        System.println("initialize SkatingMenu2Delegate");
        Menu2InputDelegate.initialize();
        _view = Application.getApp().skatingView;
        _controller = Application.getApp().controller;
        _fitManager = Application.getApp().fitManager;
    }

    function onSelect(item) {
        if (item.getId() == :menu2_darkmode) {
            if (item.isEnabled() == true) {
                _view.foregroundColor = Gfx.COLOR_WHITE;
                _view.backgroundColor = Gfx.COLOR_BLACK;
                item.setEnabled(true);
            } else {
                _view.foregroundColor = Gfx.COLOR_BLACK;
                _view.backgroundColor = Gfx.COLOR_WHITE;
                item.setEnabled(false);
            }
        } else if (item.getId() == :menu2_autolap) {
            if (item.isEnabled() == true) {

                _controller.autoLap = true;

                if (_fitManager.isRecording()) {
                    _controller.startAutoLap = Activity.getActivityInfo().elapsedDistance.toNumber();
                } else {
                    _controller.startAutoLap = 0;
                }

                _controller.nextAutoLap = _controller.startAutoLap + _controller.autoLapDistance;

                item.setEnabled(true);

            } else {
                _controller.autoLap = false;
                item.setEnabled(false);
            }
        }  
    }
}