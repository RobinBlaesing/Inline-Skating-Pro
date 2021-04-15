// https://developer.garmin.com/connect-iq/core-topics/native-controls/
using Toybox.WatchUi;
using Toybox.System;

class SkatingMenuStopDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        System.println("initialize SkatingMenuDelegate");
        MenuInputDelegate.initialize();
        session.stop();
    }

    function onMenuItem(item) {
    	if (item == :item_1) {
    		session.start();
            System.println("Continue");
        } else if (item == :item_2) {
        	SkatingApp.stopRecording(true);
            System.println("Save and exit");
        } else if (item == :item_3) {
        	SkatingApp.stopRecording(false);
            System.println("Discard and exit");
        }
    }

}