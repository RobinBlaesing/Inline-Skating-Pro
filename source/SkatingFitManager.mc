using Toybox.WatchUi;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.FitContributor;
using Toybox.System;
using Toybox.Timer;


class FitManager {

	hidden var session = null; 
	
	hidden var cadenceLast = 0.0;
	hidden var glideTimeLast = 0.0;
	hidden var strideLengthLast = 0.0;
	
	
	// Timer for updates every second
	hidden var timerSession;
	hidden var timeInit;

	// Calculate cadence by steps
	hidden var fieldCadence = null;
	hidden var fieldCadenceAvg = null;
	hidden var cadenceTimerInterval = 500.0;			// Minimum timer interval in milliseconds (should not be larger than cadenceFitInterval)
	hidden var cadenceFitInterval = 7500.0;				// Approx. fit interval in milliseconds
	hidden var cadenceRollingWindow = [[null,null]]; 	// Array of rolling window tuples (timestamp, steps)
	hidden var cadenceLimits = [0,300];
	
	// Calculate cadence by steps
	hidden var fieldGlideTime = null;
	hidden var fieldGlideTimeAvg = null;
	hidden var lastGlideTimeTuple = [null,null]; 		// Array of rolling window tuples (steps, timestamp)
	hidden var glideTimeWeightOld = 0.5;				
	hidden var glideTimeLimits = [0,120];

	// Calculate stride length by steps and elapsed distance
	hidden var fieldStrideLength = null;	
	hidden var fieldStrideLengthAvg = null;
	hidden var strideLengthTimerInterval = 500.0;			// Minimum timer interval in milliseconds (should not be larger than cadenceFitInterval)
	hidden var strideLengthFitInterval = 7500.0;			// Approx. fit interval in milliseconds
	hidden var strideLengthRollingWindow = [[null,null,null]];	// Array of rolling window tuples (steps, distance, timestamp)
	hidden var strideLengthLimits = [0,200];
	
	// In order to smooth the data, include last values in current value
	// currentValue = ( newValue + oldValue * weightOld ) / (1 + weightOld)
	hidden var weightOld = 0.5;
	
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
        recordGlideTime();
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
			fieldCadenceAvg = session.createField("cadence_avg", 1, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"spm" });
			System.println("Field fieldCadenceAvg created.");
			fieldStrideLength = session.createField("stride_length", 2, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"m" });
			System.println("Field fieldStrideLength created.");
    		fieldStrideLengthAvg = session.createField("stride_length_avg", 3, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"m" });
			System.println("Field fieldStrideLengthAvg created.");
			fieldGlideTime = session.createField("glide_time", 4, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"s" });
			System.println("Field fieldGlideTime created.");
			fieldGlideTimeAvg = session.createField("glide_time_avg", 5, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"s" });
			System.println("Field fieldGlideTimeAvg created.");
		}
	}
	
	function inLimits(value,limits){
		var returnValue = 0.0;
		returnValue = (value > limits[0]) ? value : limits[0];
		returnValue = (returnValue < limits[1]) ? returnValue : limits[1];
		return returnValue;
	}
	
	function recordAvgSessionData() {
		if (fieldCadenceAvg != null && fieldStrideLengthAvg != null && stepsAtStart != null && session != null && session.isRecording()){
			var stepsDuringSession = (ActivityMonitor.getInfo().steps - stepsAtStart).toFloat();
	    	var avgCadence = 0.0;
	    	var avgGlideTime = 0.0;
	    	var avgStrideLength = 0.0;
	    	System.println("Steps during session: " + stepsDuringSession + ", elapsed time: " + Activity.getActivityInfo().elapsedTime + ", elapsed distance: " + Activity.getActivityInfo().elapsedDistance);
	    	if (stepsDuringSession != null && stepsDuringSession > 0 && Activity.getActivityInfo().elapsedTime != null && Activity.getActivityInfo().elapsedTime > 0 && Activity.getActivityInfo().elapsedDistance != null && Activity.getActivityInfo().elapsedDistance > 0) {
		    	avgCadence = (stepsDuringSession * 60.0 / Activity.getActivityInfo().elapsedTime * 1000);
		    	avgGlideTime = (avgCadence != 0) ? (1.0/avgCadence)*60 : 0;
		    	avgStrideLength = (Activity.getActivityInfo().elapsedDistance / stepsDuringSession);
		    }
	    	fieldCadenceAvg.setData(avgCadence);
	    	fieldGlideTimeAvg.setData(avgGlideTime);
	    	fieldStrideLengthAvg.setData(avgStrideLength);
	    	System.println("Saved avg. cadence: " + avgCadence + ", and stride length: " + avgStrideLength);
    	}
    }
	
	function recordCadence(){
		var currentCadence = Activity.getActivityInfo().currentCadence;
        if (currentCadence != null && currentCadence != 0){
        	cadenceLast = (currentCadence + cadenceLast * weightOld ) / (1 + weightOld);
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
			var newCadenceLast = ((calcSlope(cadenceRollingWindow))*1000*60 + cadenceLast* weightOld ) / (1 + weightOld);
			cadenceLast = inLimits(newCadenceLast,cadenceLimits);
		} 
		if (fieldCadence != null && session != null && session.isRecording()){
    		fieldCadence.setData(inLimits(cadenceLast,cadenceLimits).toNumber()); 
    		System.println("New cadenceLast written to fieldCadence: " + cadenceLast.toNumber());
    	}
	}
    	
    function recordStrideLength(){
		var currentCadence = Activity.getActivityInfo().currentCadence;
		var currentSpeed = Activity.getActivityInfo().currentSpeed;
        if (currentCadence != null && currentCadence != 0 && currentSpeed != null && currentSpeed != 0){
        	strideLengthLast = (currentSpeed / currentCadence * 60 + strideLengthLast * weightOld ) / (1 + weightOld);
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
			var newStrideLengthLast = ((calcSlope(strideLengthRollingWindow)) + strideLengthLast* weightOld ) / (1 + weightOld);
			strideLengthLast = inLimits(newStrideLengthLast,strideLengthLimits);
 		} 
 		if (fieldStrideLength != null && session != null && strideLengthLast != null && session.isRecording()){
    		fieldStrideLength.setData(inLimits(strideLengthLast,strideLengthLimits)); 
    	}
	}
	
	function recordGlideTime(){
		var currentCadence = Activity.getActivityInfo().currentCadence;
        if (currentCadence != null && currentCadence != 0){
        	glideTimeLast = 1.0/currentCadence*60; // Glide time in seconds
		} 
		else {
			var currentSteps = ActivityMonitor.getInfo().steps;
			var elapsedTime = System.getTimer() - timeInit;
			
			var glideTimeTuple = [currentSteps,elapsedTime];
			
			if (lastGlideTimeTuple[0] != null){
				if (lastGlideTimeTuple[0] < currentSteps) {
					var avgGlideTimeWithinLastMeasInterv = (elapsedTime - lastGlideTimeTuple[1]).toFloat() / (currentSteps - lastGlideTimeTuple[0])/1000;
					glideTimeLast = avgGlideTimeWithinLastMeasInterv;
					lastGlideTimeTuple = glideTimeTuple;
    				System.println("Some steps within last check. Calc. glide time within interval: "+ avgGlideTimeWithinLastMeasInterv + ", new glide time: " + glideTimeLast);
				}
				else {
					var newGlideTime = (elapsedTime - lastGlideTimeTuple[1])/1000;
					glideTimeLast = (newGlideTime > glideTimeLast) ? (newGlideTime + glideTimeLast * glideTimeWeightOld ) / (1 + glideTimeWeightOld) : glideTimeLast;
    				System.println("No steps within last check. New glide time: " + glideTimeLast);
				}
			}
			else {
				lastGlideTimeTuple = glideTimeTuple;
			}
		} 
		if (fieldGlideTime != null && session != null && session.isRecording()){
    		fieldGlideTime.setData(inLimits(glideTimeLast,glideTimeLimits)); 
    		System.println("New cadenceLast written to fieldCadence: " + cadenceLast.toNumber());
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
    	var lapElapsedDistance = (Activity.getActivityInfo().elapsedDistance - lapDistanceAtStart).toFloat();
    	System.println("Total distance: " + Activity.getActivityInfo().elapsedDistance + ", lap distance at start: " + lapDistanceAtStart + ", elapsed distance: " + lapElapsedDistance);
    	var lapElapsedTime = ((Activity.getActivityInfo().elapsedTime - lapTimeAtStart) / 1000).toFloat();
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
    
    function getLapAvgCadence() {
    	var lapElapsedSteps = (ActivityMonitor.getInfo().steps - lapStepsAtStart).toFloat();
    	var lapElapsedTime = ((Activity.getActivityInfo().elapsedTime - lapTimeAtStart) / 1000 / 60).toFloat();
    	System.println("Lap steps: " + lapElapsedSteps + ", lap time: " + lapElapsedTime);
    	if (lapElapsedTime > 0) {
	    	lapAvgCadence = (lapElapsedSteps) / (lapElapsedTime);
    		System.println("Lap cadence: " + lapAvgCadence);
	    	return inLimits(lapAvgCadence,cadenceLimits);
	    }
	    return 0.0;
    }
    
    function getLapAvgGlideTime () {
    	var labAvgGlideTime = (getLapAvgCadence() != 0) ? 1.0/getLapAvgCadence()*60 : 0.0;
	    return inLimits(labAvgGlideTime,glideTimeLimits);
    }
    
    function getLapAvgStrideLength () {
    	var lapElapsedDistance = (Activity.getActivityInfo().elapsedDistance - lapDistanceAtStart).toFloat();
    	var lapElapsedSteps = (ActivityMonitor.getInfo().steps - lapStepsAtStart).toFloat();
    	if (lapElapsedSteps > 0) {
	    	lapAvgStrideLength = (lapElapsedDistance) / (lapElapsedSteps);
	    	return inLimits(lapAvgStrideLength,strideLengthLimits);
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
    	return (Activity.getActivityInfo().elapsedTime != 0) ? Activity.getActivityInfo().elapsedDistance.toFloat() / (Activity.getActivityInfo().elapsedTime) * 1000 : 0.0;
    }
    
    function getTotalAvgCadence () {
	    return (Activity.getActivityInfo().elapsedTime != 0) ? (ActivityMonitor.getInfo().steps.toFloat() - stepsAtStart) / Activity.getActivityInfo().elapsedTime * 1000 * 60 : 0.0;
    }
    
    function getTotalAvgGlideTime () {
    	return (getTotalAvgCadence() != 0) ? (1.0/getTotalAvgCadence())*60 : 0.0;
    }
    
    function getTotalAvgStrideLength () {
	    return (ActivityMonitor.getInfo().steps - stepsAtStart != 0) ? Activity.getActivityInfo().elapsedDistance.toFloat() / (ActivityMonitor.getInfo().steps - stepsAtStart) : 0.0;
    }
    
    
    	
    function getCadence(){
    	return inLimits(cadenceLast,cadenceLimits);
    }
    
    function getGlideTime(){
    	return inLimits(glideTimeLast,glideTimeLimits);
    }
    
    function getStrideLength(){
    	return inLimits(strideLengthLast,strideLengthLimits);
    }

}