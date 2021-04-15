using Toybox.WatchUi;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.Attention;
using Toybox.FitContributor;
using Toybox.Timer;
using Toybox.System;
	
var cadenceLast = 0.0;
var strideLengthLast = 0.0;
var timer;

class SkatingDelegate  extends WatchUi.BehaviorDelegate {	

	// Calculate cadence by steps
	var fieldCadence = null;
	var fieldCadenceAvg = null;
	var cadenceTimerInterval = 500.0;			// Minimum timer interval in milliseconds (should not be larger than cadenceFitInterval)
	var cadenceFitInterval = 8500.0;			// Approx. fit interval in milliseconds
	var cadenceRollingWindow = [[null,null]]; 	// Array of rolling window tuples (timestamp, steps)
	var timeInit;
	
	// Calculate stride length by steps and elapsed distance
	var fieldStrideLength = null;	
	var fieldStrideLengthAvg = null;
	var strideLengthTimerInterval = 500.0;			// Minimum timer interval in milliseconds (should not be larger than cadenceFitInterval)
	var strideLengthFitInterval = 8500.0;			// Approx. fit interval in milliseconds
	var strideLengthRollingWindow = [[null,null,null]];	// Array of rolling window tuples (steps, distance, timestamp)
	
	// Used to calcualte avgerage cadence and stride length:
	var stepsAtStart = null;

    function initialize() {
        System.println("initialize SkatingDelegate");
        BehaviorDelegate.initialize();
		setupTimer();
    }

    function onMenu() {
        System.println("onMenu SkatingDelegate");
        WatchUi.pushView(new Rez.Menus.MainMenu(), new SkatingMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
    
    // Example from: https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html
	
	// use the select Start/Stop or touch for recording
	function onSelect() {
	    System.println("onSelect SkatingDelegate");
	   	if (Toybox has :ActivityRecording) {                          // check device for activity recording
			if ((session == null) || (session.isRecording() == false)) {
		       	session = createSession(30);
			    if (session != null) {
	    			createFields();
			   		session.start();                                // call start session
        			stepsAtStart = ActivityMonitor.getInfo().steps;
			   		userFeedbackNotification(1);					// Give feedback that Session started
	    			System.println("Session started.");
			    }
			    else {
			   		System.println("Session failed to start. Session is null.");
			    }
                WatchUi.requestUpdate();
		    }
		    else {
				onSessionStoped();
		    }
	   	}
	   	else {
	   		// This product doesn't\nhave FIT Support
	   	}
	   	return true;                                                 // return true for onSelect function
	}
	
	function onSessionStoped () {
		System.println("onSessionStoped SkatingDelegate");
        WatchUi.pushView(new Rez.Menus.MainMenu(), new SkatingMenuStopDelegate(), WatchUi.SLIDE_UP);
        return true;
	}
	
	function createSession(value) {	
	    System.println("createSession SkatingDelegate");
		if (value == 30) {
		    var session = ActivityRecording.createSession({     // set up recording session
		        :name=>"Inline Skating",                        // set session name
		        :sport=>ActivityRecording.SPORT_INLINE_SKATING, // set sport type
		        :subSport=>ActivityRecording.SUB_SPORT_GENERIC, // set sub sport type
		    });
	    	System.println("Session created.");
		    return session;
	    }
	    return null;
	}    
	
	function createFields() {
		if (session != null && !session.isRecording()){
			fieldCadence = session.createField("cadence", 0, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"spm" });
			System.println("Field fieldCadence created.");
			fieldStrideLength = session.createField("stride_length", 1, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"m" });
			System.println("Field fieldStrideLength created.");
			fieldCadenceAvg = session.createField("cadence_avg", 2, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"spm" });
			System.println("Field fieldCadenceAvg created.");
    		fieldStrideLengthAvg = session.createField("stride_length_avg", 3, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"m" });
			System.println("Field fieldStrideLengthAvg created.");
		}
	}
	
	function recordAvgSessionData() {
		if (fieldCadenceAvg != null && fieldStrideLengthAvg != null && stepsAtStart != null && session != null && session.isRecording()){
			var stepsDuringSession = (ActivityMonitor.getInfo().steps - stepsAtStart).toFloat();
	    	var avgCadence = 0.0;
	    	var avgStrideLength = 0.0;
	    	System.println("Steps during session: " + stepsDuringSession + ", elapsed time: " + Activity.getActivityInfo().elapsedTime + ", elapsed distance: " + Activity.getActivityInfo().elapsedDistance);
	    	if (stepsDuringSession != null && stepsDuringSession > 0 && Activity.getActivityInfo().elapsedTime != null && Activity.getActivityInfo().elapsedTime > 0 && Activity.getActivityInfo().elapsedDistance != null && Activity.getActivityInfo().elapsedDistance > 0) {
		    	avgCadence = (stepsDuringSession * 60.0 / Activity.getActivityInfo().elapsedTime * 1000);
		    	avgStrideLength = (Activity.getActivityInfo().elapsedDistance / stepsDuringSession);
		    }
	    	fieldCadenceAvg.setData(avgCadence);
	    	fieldStrideLengthAvg.setData(avgStrideLength);
	    	System.println("Saved avg. cadence: " + avgCadence + ", and stride length: " + avgStrideLength);
    	}
    }
	
	function recordCadence(){
		var currentCadence = Activity.getActivityInfo().currentCadence;
        if (currentCadence != null && currentCadence != 0){
        	cadenceLast = (currentCadence + cadenceLast) / 2.0;
		} 
		else {
			var currentSteps = ActivityMonitor.getInfo().steps;
			var elapsedTime = (System.getTimer() - timeInit);
			
			// Create new tuple for fit
			var cadenceTuple = [elapsedTime,currentSteps];
			var lastCadenceTuple = cadenceRollingWindow[cadenceRollingWindow.size()-1];
			
			// Check if new data (with offset of cadenceTimerInterval)
			if (lastCadenceTuple[0] != null){
				if (elapsedTime - lastCadenceTuple[0] > cadenceTimerInterval && lastCadenceTuple[0] < elapsedTime) {
					cadenceRollingWindow.add(cadenceTuple);
				}
			}
			else {
					cadenceRollingWindow.add(cadenceTuple);
			}
			
			// Reduce array for fitting
			var newCadenceRollingWindow = [[null,null]];
			var tupleCadence;
			for( var i = 0; i < cadenceRollingWindow.size(); i += 1 ) {
				tupleCadence = cadenceRollingWindow[i];
				if (tupleCadence[0] != null && tupleCadence[1] != null && elapsedTime - tupleCadence[0] < cadenceFitInterval){
					newCadenceRollingWindow.add([tupleCadence[0],tupleCadence[1]]);
				}
			}
			cadenceRollingWindow = newCadenceRollingWindow;
			cadenceLast = (cadenceLast + (calcSlope(cadenceRollingWindow))*1000*60) / 2.0;
		} 
		if (fieldCadence != null && session != null && session.isRecording()){
    		fieldCadence.setData(cadenceLast.toNumber()); 
    		System.println("New cadenceLast written to fieldCadence: " + cadenceLast.toNumber());
    	}
	}
    	
    function recordStrideLength(){
		var currentCadence = Activity.getActivityInfo().currentCadence;
		var currentSpeed = Activity.getActivityInfo().currentSpeed;
        if (currentCadence != null && currentCadence != 0 && currentSpeed != null && currentSpeed != 0){
        	strideLengthLast = (currentSpeed / currentCadence * 60 + strideLengthLast) / 2.0;
 		} 
 		else {
			var currentSteps = ActivityMonitor.getInfo().steps;
			var elapsedDistance = Activity.getActivityInfo().elapsedDistance;
			var elapsedTime = (System.getTimer() - timeInit);
			
			// Create new tuple for fit
			var strideLengthTuple = [currentSteps,elapsedDistance,elapsedTime];
			var lastStrideLengthTuple = strideLengthRollingWindow[strideLengthRollingWindow.size()-1];
			
			// Check if new data (with offset of cadenceTimerInterval)
			if (lastStrideLengthTuple[2] != null){
				if (elapsedTime - lastStrideLengthTuple[2] > strideLengthTimerInterval && lastStrideLengthTuple[2] < elapsedTime) {
					strideLengthRollingWindow.add(strideLengthTuple);
				}
			}
			else {
					strideLengthRollingWindow.add(strideLengthTuple);
			}
			
			// Reduce array for fitting
			var newStrideLengthRollingWindow = [[null,null,null]];
			var tupleStrideLength;
			for( var i = 0; i < strideLengthRollingWindow.size(); i += 1 ) {
				tupleStrideLength = strideLengthRollingWindow[i];
				if (tupleStrideLength[2] != null && tupleStrideLength[1] != null && tupleStrideLength[0] != null && elapsedTime - tupleStrideLength[2] < strideLengthFitInterval){
					newStrideLengthRollingWindow.add([tupleStrideLength[0],tupleStrideLength[1],tupleStrideLength[2]]);
				}
			}
			strideLengthRollingWindow = newStrideLengthRollingWindow;
			strideLengthLast = (strideLengthLast + (calcSlope(strideLengthRollingWindow))) / 2.0;
 		} 
 		if (fieldStrideLength != null && session != null && strideLengthLast != null && session.isRecording()){
    		fieldStrideLength.setData(strideLengthLast); 
    		System.println("New strideLengthLast written to fieldStrideLength: " + strideLengthLast);
    	}
	}
	
		function calcSlope(tupleArray){
    		var n = tupleArray.size();
    		var tuple;
    		var sumXY = 0.0; 				
    		var sumX = 0.0;
    		var sumY = 0.0;			
    		var sumXsq = 0.0;
			for( var i = 0; i < tupleArray.size(); i += 1 ) {
				tuple = tupleArray[i];
				if (tuple[0] != null && tuple[1] != null){
					sumXY += (tuple[0] / 1000.0 * tuple[1] / 1000.0);
					sumX += (tuple[0] / 1000.0);
					sumY += (tuple[1] / 1000.0);
					sumXsq += (tuple[0] / 1000.0 * tuple[0] / 1000.0);
				}
				else {
					n--;
				}
			}
			return (n > 2 && (n * sumXsq - sumX * sumX) != 0) ? (n * sumXY - sumX * sumY) / (n * sumXsq - sumX * sumX) : 0;
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
	
	// Timer:
    
    function setupTimer() {
	    timer = new Timer.Timer();
	    timer.start(method(:updateEverySecond), 1000, true);
		timeInit = System.getTimer();
	}
	
	function updateEverySecond(){
		recordCadence();
		recordStrideLength();
        recordAvgSessionData();
	    WatchUi.requestUpdate();
	}

}