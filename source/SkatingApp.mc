using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Sensor;
using Toybox.Attention;

class SkatingApp extends Application.AppBase {

	var controller;
	var skatingView;
	var fitManager;
    var menu2;
    var menu2Delegate;
    var menu2unlock;
    var menu2unlockDelegate;
    var menu2genkey;
    var menu2genkeyDelegate;

    function initialize() {
        AppBase.initialize();
        System.println("initialize Skating App");
        fitManager = new $.FitManager(); 
        skatingView = new $.SkatingView();
        controller = new $.Controller();
        menu2 = new Rez.Menus.Menu2();
        menu2Delegate = new $.Menu2Delegate();
        menu2unlock = new Rez.Menus.Menu2unlock();
        menu2unlockDelegate = new $.Menu2unlockDelegate();
        menu2genkey = new Rez.Menus.Menu2genkey();
        menu2genkeyDelegate = new $.Menu2genkeyDelegate();
    }

    // onStart() is called on application start up
    function onStart(state) {
        System.println("onStart Skating App");
        Sensor.enableSensorType(Sensor.SENSOR_TECHNOLOGY_BLE);
        Sensor.enableSensorType(Sensor.SENSOR_TECHNOLOGY_ANT);
        Sensor.enableSensorType(Sensor.SENSOR_FOOTPOD);
        Sensor.enableSensorType(Sensor.SENSOR_TECHNOLOGY_ONBOARD);
        //Sensor.enableSensorEvents(method(:onSensor));
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
        return [ new SkatingInitView(), new WatchUi.BehaviorDelegate() ];
    }

}
