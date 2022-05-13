using Toybox.WatchUi;
using Toybox.System;
using Toybox.Timer;
using Toybox.Application;
using Toybox.Attention;
using Toybox.Position;


class Controller {

	hidden var _fitManager;
	hidden var _skatingView;
	
	hidden var device;
	
	// View controll:
	hidden var status;
	hidden var hasLab = false;
	
	hidden var timerUpdate;
	
	const STAT_IDLE = 0;
	const STAT_INIT = 1;
	const STAT_STD = 2;
	const STAT_LAP = 3;
	const STAT_TOTAL = 4;
	const STAT_MAP = 5;
	
	var firstView = STAT_STD;
	var lastView = STAT_TOTAL;

	var autoLap;
	var autoLapDistance = 50;
	var startAutoLap;		//set by Menu2Delegate
	var nextAutoLap;		//initially set by Menu2Delegate
	

	function initialize() {
		_fitManager = Application.getApp().fitManager;
		_skatingView = Application.getApp().skatingView;
		status = STAT_IDLE;
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        setupTimer();
        device = WatchUi.loadResource(Rez.Strings.device_type);
    }
    
    // Timer:
	
	function setupTimer() {
		timerUpdate = new Timer.Timer();
		timerUpdate.start(method(:removeInitViewAndStartUp), 1200, false);
	}
	
		function updateEverySecond(){
			_fitManager.updateFitData();
			var dist = Activity.getActivityInfo().elapsedDistance;
			if(autoLap == true){
				if (_fitManager.isRecording() && dist != null) {
					if (dist > nextAutoLap) {
						handleLap();
						nextAutoLap = nextAutoLap + autoLapDistance;
					}
				}	
			}
			
			
		    WatchUi.requestUpdate();
		}
	
    
    function removeInitViewAndStartUp (){
    	WatchUi.switchToView(_skatingView, new SkatingDelegate(), WatchUi.SLIDE_RIGHT);
		timerUpdate.start(method(:updateEverySecond), 1000, true);
    }
    
    function onPosition(info) {
		//_skatingView.updatePosition(info);
    	//WatchUi.requestUpdate();
    }
    
    function handleStartStop(){
    	if (_fitManager.hasSession() == false) { // Inital start
			_fitManager.sessionStart();
			status = STAT_STD;
    		_skatingView.manageStatus(status);
	   		userFeedbackNotification(1);					// Give feedback that Session started
	    }
	    else { // During activity
			WatchUi.pushView(new Rez.Menus.MainMenu(), new SkatingMenuStopDelegate(), WatchUi.SLIDE_UP);
	   		userFeedbackNotification(0);					// Give feedback that Session paused
	    }
    }
    
    function handleLap(){
    	if (_fitManager.isRecording()) {
    		_fitManager.newSessionLap();
    		hasLab = true;
    		if (status == STAT_MAP) {
				WatchUi.popView(WatchUi.SLIDE_RIGHT);
				WatchUi.requestUpdate();
			} 
	    	status = STAT_LAP;
	    	_skatingView.manageStatus(status);
	    	userFeedbackNotification(2);
	    }
	    else if (_fitManager.hasSession()){
	    	WatchUi.pushView(new Rez.Menus.MainMenu(), new SkatingMenuStopDelegate(), WatchUi.SLIDE_UP);
	    }
	    else {
	    	System.exit();
	    }
    }
    
    function handlePageSwitch(switchPage){
    	var posInfo = Position.getInfo();
        if (device.equals("maps") && (posInfo.accuracy > 3)) {
        	lastView = STAT_MAP;
        }
    	if (status != STAT_IDLE && status != STAT_INIT){
	    	var initStatus = status;
	    	System.println("Incomming status: " + initStatus + ". switchPage: " + switchPage);
			if (status == STAT_MAP) {
				WatchUi.popView(WatchUi.SLIDE_RIGHT);
				WatchUi.requestUpdate();
			}
	    	if (hasLab){
	    		if (switchPage > 0 && status >= lastView) {
	    			status = firstView;
	    		} else if (switchPage < 0 && status <= firstView) {
	    			status = lastView;
	    		} else {
	    			status += switchPage;
	    		}
	    	} 
	    	else {
	    		status += switchPage;
	    		if (status == STAT_LAP){
	    			status += switchPage;
	    		} else if (status > lastView){
	    			status = firstView;
	    		} else if (status < firstView){
	    			status = lastView;
	    		}
	    	}
	    	System.println("Handle page switch. Has Lab: " + hasLab + ". New status: " + status);
			if (initStatus != status && status != STAT_MAP) {
				_skatingView.manageStatus(status);
			}
			if (status == STAT_MAP) {
				WatchUi.pushView(new SkatingMapView(), new SkatingDelegate(), WatchUi.SLIDE_LEFT);
			}
			WatchUi.requestUpdate();
		}
    }
    
    function stopRecording(save){
    	_fitManager.stopRecording(save);
    	userFeedbackNotification(0);
    }
    
    function getStatus(){
    	return status;
    }
    	
	
	function userFeedbackNotification(eventType) {
		var toneProfile = null;
		var vibeData = null;
		var attentionTone = null;
		if (Attention has :playTone) {
			if (eventType == 0) { // Stop & pause
				attentionTone = Attention.TONE_STOP;
				vibeData = [
			        new Attention.VibeProfile(25, 200)
			    ];
			}
			if (eventType == 1) { // Start
				attentionTone = Attention.TONE_START;
				vibeData = [
			        new Attention.VibeProfile(100, 400),
			        new Attention.VibeProfile(1, 1),
			        new Attention.VibeProfile(50, 200),
			        new Attention.VibeProfile(1, 1),
			        new Attention.VibeProfile(25, 200)
			    ];
			} 
			if (eventType == 2) { // Lap
				attentionTone = Attention.TONE_LAP;
				vibeData = [
			        new Attention.VibeProfile(100, 100),
			        new Attention.VibeProfile(1, 1),
			        new Attention.VibeProfile(100, 100)
			    ];
			} 
			if (eventType == 3) { // Continue
				toneProfile = [
			        new Attention.ToneProfile(523 , 200)
				];
				vibeData = [
			        new Attention.VibeProfile(20, 200)
			    ];
			} 
			if (eventType == 4) { // Save
				attentionTone = Attention.TONE_SUCCESS;
				vibeData = [
			        new Attention.VibeProfile(20, 100),
			        new Attention.VibeProfile(5, 100),
			        new Attention.VibeProfile(100, 100)
			    ];
			} 
			if (eventType == 5) { // Discard
				toneProfile = [
			        new Attention.ToneProfile( 294 , 250),
			        new Attention.ToneProfile( 1 , 10),
			        new Attention.ToneProfile( 262 , 250)
				];
				vibeData = [
			        new Attention.VibeProfile(50, 250),
			        new Attention.VibeProfile(1, 10),
			        new Attention.VibeProfile(20, 250)
			    ];
			} 
			if (eventType == 6) { // on stop
				toneProfile = [
			        new Attention.ToneProfile( 262 , 250),
			        new Attention.ToneProfile( 294 , 250),
			        new Attention.ToneProfile( 330 , 250),
			        new Attention.ToneProfile( 349 , 250),
			        new Attention.ToneProfile( 392 , 500),
			        new Attention.ToneProfile( 392 , 500),
			        new Attention.ToneProfile( 440 , 250),
			        new Attention.ToneProfile( 440 , 250),
			        new Attention.ToneProfile( 440 , 250),
			        new Attention.ToneProfile( 440 , 250),
			        new Attention.ToneProfile( 392 , 1000),
			        new Attention.ToneProfile( 440 , 250),
			        new Attention.ToneProfile( 440 , 250),
			        new Attention.ToneProfile( 440 , 250),
			        new Attention.ToneProfile( 440 , 250),
			        new Attention.ToneProfile( 392 , 1000),
			        new Attention.ToneProfile( 349 , 250),
			        new Attention.ToneProfile( 349 , 250),
			        new Attention.ToneProfile( 349 , 250),
			        new Attention.ToneProfile( 349 , 250),
			        new Attention.ToneProfile( 330 , 500),
			        new Attention.ToneProfile( 330 , 500),
			        new Attention.ToneProfile( 294 , 250),
			        new Attention.ToneProfile( 294 , 250),
			        new Attention.ToneProfile( 294 , 250),
			        new Attention.ToneProfile( 294 , 250),
			        new Attention.ToneProfile( 262 , 1000),
			        new Attention.ToneProfile( 494 , 250),
			        new Attention.ToneProfile( 523 , 250)
			    ];
			    vibeData = [
			        new Attention.VibeProfile(25, 2000),
			        new Attention.VibeProfile(50, 2000),
			        new Attention.VibeProfile(100, 2000)
			    ];
			}
			// Play
			if (Attention has :playTone && attentionTone != null) {
			   Attention.playTone(attentionTone);
			}
			if (Attention has :ToneProfile && toneProfile != null) {
			    Attention.playTone({:toneProfile=>toneProfile});
		   	}
	   		if (Attention has :vibrate && vibeData != null) {
				Attention.vibrate(vibeData);
			}
		}
	}
	
}
	