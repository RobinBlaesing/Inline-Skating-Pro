using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;


class Menu2Delegate extends WatchUi.Menu2InputDelegate {

    hidden var _view;
    hidden var _controller;
    hidden var _fitManager;
    hidden var _menu2;

    function initialize() {
        System.println("initialize SkatingMenu2Delegate");
        Menu2InputDelegate.initialize();
        _view = Application.getApp().skatingView;
        _controller = Application.getApp().controller;
        _fitManager = Application.getApp().fitManager;
        _menu2 = Application.getApp().menu2;

        //get Settings - what is enabled, what isn't:
        if (Application.Properties.getValue("darkModeOn") == true) {
            _menu2.getItem(0).setEnabled(true);
        } else {
            _menu2.getItem(0).setEnabled(false);
        }

        if (Application.Properties.getValue("autoLapOn") == true) {
            _menu2.getItem(1).setEnabled(true);
        } else {
            _menu2.getItem(1).setEnabled(false);
        }

        if (Application.Properties.getValue("autoPauseOn") == true) {
            _menu2.getItem(2).setEnabled(true);
        } else {
            _menu2.getItem(2).setEnabled(false);
        }        



    }

    function onSelect(item) {
        if (item.getId() == :menu2_darkmode) {

            if (item.isEnabled() == true) {
                _view.foregroundColor = Gfx.COLOR_WHITE;
                _view.backgroundColor = Gfx.COLOR_BLACK;
                Application.Properties.setValue("darkModeOn", true);
                item.setEnabled(true);
            } else {
                _view.foregroundColor = Gfx.COLOR_BLACK;
                _view.backgroundColor = Gfx.COLOR_WHITE;
                Application.Properties.setValue("darkModeOn", false);
                item.setEnabled(false);
            }

        } else if (item.getId() == :menu2_autolap) {
            if (item.isEnabled() == true) {

                _controller.autoLapSetting = true;

                if (_fitManager.isRecording()) {
                    _controller.startAutoLap = Activity.getActivityInfo().elapsedDistance.toNumber();
                } else {
                    _controller.startAutoLap = 0;
                }

                _controller.nextAutoLap = _controller.startAutoLap + _controller.autoLapDistance;

                Application.Properties.setValue("autoLapOn", true);
                item.setEnabled(true);

            } else {
                _controller.autoLapSetting = false;
                Application.Properties.setValue("autoLapOn", false);
                item.setEnabled(false);
            }
            
        } else if (item.getId() == :menu2_autopause) {
            if (item.isEnabled() == true) {
                Application.Properties.setValue("autoPauseOn", true);
                _controller.autoPauseSetting = true;
            } else {
                _controller.autoPauseSetting = false;
                Application.Properties.setValue("autoPauseOn", false);
            }
        }  
    }
}