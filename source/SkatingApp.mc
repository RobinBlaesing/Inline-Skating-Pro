using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Sensor;
using Toybox.Attention;

class SkatingApp extends Application.AppBase {

	var controller;
	var skatingView;
	var fitManager;

    function initialize() {
        AppBase.initialize();
        System.println("initialize Skating App");
        fitManager = new $.FitManager(); 
        skatingView = new $.SkatingView();
        controller = new $.Controller();
    }

    // onStart() is called on application start up
    function onStart(state) {
        System.println("onStart Skating App");
        Sensor.enableSensorEvents(method(:onSensor));
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        System.println("onStop Skating App");
    }
    
    function onSensor(info) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        System.println("getInitialView Skating App");
        return [ skatingView, new SkatingDelegate() ];
    }

}
