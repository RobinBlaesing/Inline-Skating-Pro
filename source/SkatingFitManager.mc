using Toybox.WatchUi;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.FitContributor;
using Toybox.System;
using Toybox.Timer;


class FitManager {

	hidden var session = null; 
	hidden var cadenceLast = 0.0;
	hidden var strideLengthLast = 0.0;

	// Calculate cadence by steps
	hidden var fieldCadence = null;
	hidden var fieldCadenceAvg = null;
	hidden var cadenceTimerInterval = 500.0;			// Minimum timer interval in milliseconds (should not be larger than cadenceFitInterval)
	hidden var cadenceFitInterval = 8500.0;			// Approx. fit interval in milliseconds
	hidden var cadenceRollingWindow = [[null,null]]; 	// Array of rolling window tuples (timestamp, steps)
	hidden var timeInit;
	
	
	// Timer for updates every second
	hidden var timerSession;

	
	// Calculate stride length by steps and elapsed distance
	hidden var fieldStrideLength = null;	
	hidden var fieldStrideLengthAvg = null;
	hidden var strideLengthTimerInterval = 500.0;			// Minimum timer interval in milliseconds (should not be larger than cadenceFitInterval)
	hidden var strideLengthFitInterval = 8500.0;			// Approx. fit interval in milliseconds
	hidden var strideLengthRollingWindow = [[null,null,null]];	// Array of rolling window tuples (steps, distance, timestamp)
	
	// Used to calcualte avgerage cadence and stride length:
	hidden var stepsAtStart = null;
	
	// Lap variables
	hidden var lapTimeAtStart = 0.0;
	hidden var lapDistanceAtStart = 0.0;
	hidden var lapStepsAtStart = 0.0;
	
	hidden var lapAvgVelocity = 0.0;
	hidden var lapAvgCadence = 0.0;
	hidden var lapAvgStrideLength = 0.0;
	
	
	function initialize (){
		timeInit = System.getTimer();
		timerSession = new Timer.Timer();
	}
	
		
	function updateFitData(){
		recordCadence();
		recordStrideLength();
        recordAvgSessionData();
	}
	
	
	function sessionStart () {
	    session = createSession(30);
	    if (session != null) {
	    	createFields();
	   		session.start();                                // call start session
			stepsAtStart = ActivityMonitor.getInfo().steps;
			System.println("Session started.");
	    }
	    else {
	   		System.println("Session failed to start. Session is null.");
	    }
        WatchUi.requestUpdate();
	 }
    
    function sessionStop () {
		System.println("onSessionStoped SkatingDelegate");
        WatchUi.pushView(new Rez.Menus.MainMenu(), new SkatingMenuStopDelegate(), WatchUi.SLIDE_UP);
        return true;
	}
	
	function newSessionLap () {
		session.addLap();
		lapTimeAtStart = Activity.getActivityInfo().elapsedTime.toFloat();
		lapDistanceAtStart = Activity.getActivityInfo().elapsedDistance.toFloat();
		lapStepsAtStart = ActivityMonitor.getInfo().steps.toFloat();
	}
	
	function hasSession(){
		return (session != null);
	}
	
	function isRecording(){
		return (hasSession()) ? session.isRecording() : false;
	}
	
	function pauseSession(){
		session.stop();
	}
	
	function continueSession(){
		session.start();
	}
	
    
    function stopRecording(save) {
		timerSession.stop();
        //Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        if( Toybox has :ActivityRecording ) {
            if (session != null) {
		       	                                     // stop the session
		       	if (save) {
			   		session.save();									// save the session
			   		System.println("--- Session saved! ---");
			   	}
			   	else {
			   		session.discard();								// discard the session
			   	}
			    session = null;                                     // set session control variable to null
                WatchUi.requestUpdate();
	    		System.println("Session stopped.");
		        System.exit();
		    }
        }
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
    	
    	
    function getLapAvgVelocity () {
    	var lapElapsedDistance = Activity.getActivityInfo().elapsedDistance - lapDistanceAtStart;
    	System.println("Total distance: " + Activity.getActivityInfo().elapsedDistance + ", lap distance at start: " + lapDistanceAtStart + ", elapsed distance: " + lapElapsedDistance);
    	var lapElapsedTime = (Activity.getActivityInfo().elapsedTime - lapTimeAtStart) / 1000;
    	if (lapElapsedTime > 0) {
	    	lapAvgVelocity = (lapElapsedDistance) / (lapElapsedTime);
	    	return lapAvgVelocity;
	    }
	    return 0.0;
    }
    
    function getLapDistance () {
    	var lapElapsedDistance = Activity.getActivityInfo().elapsedDistance - lapDistanceAtStart;
    	if (lapElapsedDistance == null || lapElapsedDistance == 0){
    		return 0.0;
    	}
	    return lapElapsedDistance;
    }
    
    function getLapAvgCadence () {
    	var lapElapsedSteps = ActivityMonitor.getInfo().steps - lapStepsAtStart;
    	var lapElapsedTime = (Activity.getActivityInfo().elapsedTime - lapTimeAtStart) / 1000 / 60;
    	System.println("Lap steps: " + lapElapsedSteps + ", lap time: " + lapElapsedTime);
    	if (lapElapsedTime > 0) {
	    	lapAvgCadence = (lapElapsedSteps) / (lapElapsedTime);
    		System.println("Lap cadence: " + lapAvgCadence);
	    	return lapAvgCadence;
	    }
	    return 0.0;
    }
    
    function getLapAvgStrideLength () {
    	var lapElapsedDistance = Activity.getActivityInfo().elapsedDistance - lapDistanceAtStart;
    	var lapElapsedSteps = ActivityMonitor.getInfo().steps - lapStepsAtStart;
    	if (lapElapsedSteps > 0) {
	    	lapAvgStrideLength = (lapElapsedDistance) / (lapElapsedSteps);
	    	return lapAvgStrideLength;
	    }
	    return 0.0;
    }
    
    function getLapTime () {
    	var lapElapsedTime = Activity.getActivityInfo().elapsedTime - lapTimeAtStart;
    	if (lapElapsedTime == null || lapElapsedTime == 0){
    		return 0.0;
    	}
	    return lapElapsedTime;
    }
    
    
    
    function getTotalAvgVelocity () {
    	return (Activity.getActivityInfo().elapsedTime != 0) ? Activity.getActivityInfo().elapsedDistance / (Activity.getActivityInfo().elapsedTime) * 1000 : 0.0;
    }
    
    function getTotalAvgCadence () {
	    return (Activity.getActivityInfo().elapsedTime != 0) ? (ActivityMonitor.getInfo().steps.toFloat() - stepsAtStart) / Activity.getActivityInfo().elapsedTime * 1000 * 60 : 0.0;
    }
    
    function getTotalAvgStrideLength () {
	    return (ActivityMonitor.getInfo().steps - stepsAtStart != 0) ? Activity.getActivityInfo().elapsedDistance / (ActivityMonitor.getInfo().steps - stepsAtStart) : 0.0;
    }
    
    
    	
    function getCadence(){
    	return cadenceLast;
    }
    
    function getStrideLength(){
    	return strideLengthLast;
    }

}