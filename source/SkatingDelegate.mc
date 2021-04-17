using Toybox.WatchUi;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.FitContributor;

class SkatingDelegate  extends WatchUi.BehaviorDelegate {		

	hidden var _controller;

    function initialize() {
        System.println("initialize SkatingDelegate");
        BehaviorDelegate.initialize();
        _controller = Application.getApp().controller;
    }

    function onMenu() {
        System.println("onMenu SkatingDelegate");
        WatchUi.pushView(new Rez.Menus.MainMenu(), new SkatingMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
    
    // Example from: https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html
	
	
	function onSelect() {
	    System.println("onSelect SkatingDelegate");
	   	if (Toybox has :ActivityRecording) {                          // check device for activity recording
	   		_controller.handleStartStop();
	   	}
	   	else {
	   		// This product doesn't\nhave FIT Support
	   	}
	   	return true;                                                 // return true for onSelect function
	}
	
	// New lap
	function onBack() {
	    System.println("onBack SkatingDelegate");
		if (Toybox has :ActivityRecording) {                          // check device for activity recording
	   		_controller.handleLap();
	   	}
	   	else {
	   		// This product doesn't\nhave FIT Support
	   	}
	   	return true;   
	}
	
	function onPreviousPage() {
		_controller.handlePageSwitch(-1);
	}
	
	function onNextPage() {
		_controller.handlePageSwitch(1);
	}

}