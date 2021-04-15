using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Sensor;

var session = null; 
var skatingView;

class SkatingApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        System.println("initialize Skating App");
    }

    // onStart() is called on application start up
    function onStart(state) {
        System.println("onStart Skating App");
        Sensor.enableSensorEvents(method(:onSensor));
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        System.println("onStop Skating App");
        var confirmExit = new WatchUi.Confirmation("Save and exit?");
		WatchUi.pushView( confirmExit, new SaveConfirmationDelegate(), WatchUi.SLIDE_RIGHT );
    }
    
    function stopRecording(save) {
		timer.stop();
        //Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        if( Toybox has :ActivityRecording ) {
            if (session != null) {
		       	session.stop();                                     // stop the session
		       	if (save) {
			   		session.save();									// save the session
			   		System.println("--- Session saved! ---");
			   	}
			   	else {
			   		session.discard();								// discard the session
			   	}
			    session = null;                                     // set session control variable to null
                WatchUi.requestUpdate();
			   	SkatingDelegate.userFeedbackNotification(0);		// Give feedback that Session started
	    		System.println("Session stopped.");
		        System.exit();
		    }
        }
    } 
    
    function onPosition(info) {
    	skatingView.updatePosition(info);
    	WatchUi.requestUpdate();
    }
    
    function onSensor(info) {
    	//skatingView.dasd();
    }

    // Return the initial view of your application here
    function getInitialView() {
        System.println("getInitialView Skating App");
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        skatingView = new SkatingView();
        return [ skatingView, new SkatingDelegate() ];
    }

}
