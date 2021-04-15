using Toybox.WatchUi;
using Toybox.System;

/*
class StopConfirmationDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
        	session.stop();
            System.println("StopConfirmationDelegate: Stop.");
        } else {
            System.println("StopConfirmationDelegate: Not stopping. Return");
        }
    }
} */

class SaveConfirmationDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            System.println("SaveConfirmationDelegate: Stopping and saving session.");
            SkatingApp.stopRecording(true);
        } else {
            System.println("SaveConfirmationDelegate: Stopping and discarding session.");
            SkatingApp.stopRecording(false);
        }
    }
}