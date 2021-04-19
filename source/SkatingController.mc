using Toybox.WatchUi;
using Toybox.System;
using Toybox.Timer;
using Toybox.Application;
using Toybox.Attention;


class Controller {

	hidden var _fitManager;
	hidden var _skatingView;
	
	// View controll:
	hidden var status;
	hidden var hasLab = false;
	
	hidden var timerUpdate;
	
	const STAT_IDLE = 0;
	const STAT_INIT = 1;
	const STAT_STD = 2;
	const STAT_LAP = 3;
	const STAT_TOTAL = 4;
	

	function initialize() {
		_fitManager = Application.getApp().fitManager;
		_skatingView = Application.getApp().skatingView;
		status = STAT_IDLE;
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        setupTimer();
    }
    
    // Timer:
	
	function setupTimer() {
		timerUpdate = new Timer.Timer();
		timerUpdate.start(method(:removeInitViewAndStartUp), 1200, false);
	}
	
		function updateEverySecond(){
			_fitManager.updateFitData();
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
    	if ((_fitManager.hasSession() == null) || (_fitManager.isRecording() == false)) {
    		_fitManager.sessionStart();
			status = STAT_STD;
    		_skatingView.manageStatus(status);
	   		userFeedbackNotification(1);					// Give feedback that Session started
	    }
	    else {
			_fitManager.sessionStop();
	   		userFeedbackNotification(0);					// Give feedback that Session started
	    }
    }
    
    function handleLap(){
    	if (_fitManager.isRecording()) {
    		_fitManager.newSessionLap();
    		hasLab = true;
	    	status = STAT_LAP;
	    	_skatingView.manageStatus(status);
	    }
	    else {
	    	System.exit();
	    }
    }
    
    function handlePageSwitch(switchPage){
    	var initStatus = status;
    	System.println("Incomming status: " + initStatus + ". switchPage: " + switchPage);
    	if (hasLab){
    		if (switchPage > 0 && status == STAT_TOTAL) {
    			status = STAT_STD;
    		} else if (switchPage < 0 && status == STAT_STD) {
    			status = STAT_TOTAL;
    		} else {
    			status += switchPage;
    		}
    	} 
    	else {
    		if (status == STAT_STD){
    			status = STAT_TOTAL;
    		} else if (status == STAT_TOTAL){
    			status = STAT_STD;
    		}
    	}
    	System.println("Handle page switch. Has Lab: " + hasLab + ". New status: " + status);
		if (initStatus != status) {
			_skatingView.manageStatus(status);
		}
    }
    
    function stopRecording(save){
    	_fitManager.stopRecording(save);
    	userFeedbackNotification(0);
    }
    
    function getStatus(){
    	return status;
    }
    	
	
	function userFeedbackNotification(start) {
		var toneProfile = null;
		var vibeData = null;
		var attentionTone = null;
		if (start == 0) {
			attentionTone = Attention.TONE_STOP;
			vibeData = [
		        new Attention.VibeProfile(25, 200),
		        new Attention.VibeProfile(50, 200),
		        new Attention.VibeProfile(100, 400)
		    ];
		}
		if (start == 1) {
			attentionTone = Attention.TONE_START;
			vibeData = [
		        new Attention.VibeProfile(100, 400),
		        new Attention.VibeProfile(50, 200),
		        new Attention.VibeProfile(25, 200)
		    ];
		} 
		if (start == 2) { // on stop
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
		if (Attention has :playTone && attentionTone != null) {
		   //Attention.playTone(attentionTone);
		}
		if (Attention has :ToneProfile && toneProfile != null) {
		    //Attention.playTone({:toneProfile=>toneProfile});
	   	}
   		if (Attention has :vibrate && vibeData != null) {
			//Attention.vibrate(vibeData);
		}
	}
	
}
	