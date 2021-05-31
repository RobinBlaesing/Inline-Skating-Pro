using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Application;
using Toybox.System as Sys;
using Toybox.UserProfile;
using Toybox.Timer;

class SkatingView extends Ui.View {

	hidden var _fitManager;
	
	hidden var status;

	var customIcons = null;
	// customIcons
	const ICON_HEART = "0";
	const ICON_ALARM = "1";
	const ICON_BLUETOOTH = "2";
	const ICON_NOTIFICATION = "3";
	const ICON_MOON = "4";
	const ICON_BATTERY = "5";

	var iconsConnected = null;
	// iconsConnected
	const ICON_CONNECTED_PHONE = "0";
	const ICON_CONNECTED_BLUETOOTH = "1";
	const ICON_CONNECTED_HEART_EMPTY = "2";
	const ICON_CONNECTED_HEART_FILLED = "3";

	// --- Layers ---
	// General:
	var gridLayer;
	var batteryLayer;
	var clockLayer;
	var iconsConnectedLayer;
	var accuracyLayer;
	var viewNameLayer;
	// Std. layers:
	var heartRateLayer;
	var speedLayer;
	var distanceLayer;
	//var cadenceLayer;
	//var glideTimeLayer;
	//var strideLengthLayer;
	var energyExpenditureLayer;
	var timerLayer;
	var trainingEffectLayer;
	var caloriesLayer;
	// Total Layers:
	var totalAvgSpeedLayer;
	var totalAvgCadenceLayer;
	var totalAvgGlideTimeLayer;
	var totalAvgStrideLengthLayer;
	var maxSpeedLayer;
	var maxHeartRateLayer;
	// Lap Layers:
	var lapAvgSpeedLayer;
	var lapDistanceLayer;
	var lapAvgCadenceLayer;
	var lapAvgGlideTimeLayer;
	var lapAvgStrideLengthLayer;
	var lapTimeLayer;
	
	var top;
	var upperLeft;
    var upperRight;
    var lowerLeft;
    var lowerRight;
    var bottom;
    var bottomLeft;
    var bottomRight;
    var full;
	
	// TODOs:
	// Training effect
	// Calories
	// max speed
	// max heart rate
	// total descent
	// total ascent
	// LABS FOR:
	// 		Stride length
	//		Cadence
	//		Speed
	//		Distance
	//		Timer
	
	// Parameters
	var lowBatteryThreshold;				// Can be set in initialize()
	
	// Layout settings
	var sw;									// Screen width in %
	var sh;									// Screen height in %
	var foregroundColor;					// Can be set in initialize()
	var backgroundColor;					// Can be set in initialize()
	var stdScreenSize;						// Can be set in initialize()
	var screenSizeScale = 1.0; 				// Is adjusted in onLayout()
	var stdFont; 							// Can be set in initialize()
	var stdFontHeight; 						// Is adjusted in onLayout()

    function initialize() {
        System.println("initialize SkatingView");
        View.initialize();
        
        _fitManager = Application.getApp().fitManager;
        
        // Custom resources
    	customIcons = Ui.loadResource(Rez.Fonts.customIcons);
    	iconsConnected = Ui.loadResource(Rez.Fonts.iconsConnected);
        
        // Custom initialization values
        
        // Battery threshold:
        lowBatteryThreshold = 10; // (unit: %) Values 1 - 99
        
        // Custom colors:
        foregroundColor = Gfx.COLOR_BLACK;
		backgroundColor = Gfx.COLOR_WHITE;
		
		// Screen & font size:
		stdScreenSize = 240.0;
		stdFont = Gfx.FONT_MEDIUM;
    }

    // Load your resources here
    function onLayout(dc) {    
        System.println("onLayout SkatingView");
        
        dc.setColor(foregroundColor, backgroundColor);
        dc.clear();
        
        sw = dc.getWidth() / 100.0;		// Screen width in percent
        sh = dc.getHeight() / 100.0;	// Screen height in percent
        
        // Fit all displayed items to screen dimensions:
		stdFontHeight = Gfx.getFontHeight(stdFont);
        screenSizeScale = 100*sw / stdScreenSize.toFloat();
        rescaleStdFont();
        System.println("Screen width: " + 100*sw + " -> scale factor: " + screenSizeScale.format("%f") + " --> font size: " + stdFont);
        
        // Grid with data fields:
        top = {:locX=>20*sw, :locY=>0.5*sh, :width=>60*sw, :height=>23*sh};
		upperLeft = {:locX=>15, :locY=>62, :width=>scale(100), :height=>scale(57)};
		upperRight = {:locX=>126, :locY=>62, :width=>scale(100), :height=>scale(57)};
		lowerLeft = {:locX=>15, :locY=>122, :width=>scale(100), :height=>scale(57)};
		lowerRight = {:locX=>126, :locY=>122, :width=>scale(100), :height=>scale(57)};
    	bottomLeft = {:locX=>20.5*sw, :locY=>76*sh, :width=>27.5*sw, :height=>16*sh};
    	bottomRight = {:locX=>51.5*sw, :locY=>76*sh, :width=>27.5*sw, :height=>16*sh};
		bottom = {:locX=>20*sw, :locY=>92*sh, :width=>60*sw, :height=>8*sh};
		full = {:locX=>0, :locY=>0, :width=>100*sw-1, :height=>100*sh-1};
		//var bottom = {:locX=>35*sw, :locY=>86*sh, :width=>30*sw, :height=>12.5*sh};
        
        manageStatus (Controller.STAT_INIT);
    }
    
    // Call manageStatus if status changed
    function manageStatus (stat) {
    	status = stat;
    	clearLayers();    
    	
    	gridLayer = new Ui.Layer(full);
	    addLayer(gridLayer);
    	
    	if (status == Controller.STAT_INIT) {	  
    		System.println("View status changed: " +  status);
    		
	        iconsConnectedLayer = new Ui.Layer({:locX=>64*sw, :locY=>8.5*sh, :width=>30, :height=>30});
	        addLayer(iconsConnectedLayer);
	        
	        accuracyLayer = new Ui.Layer({:locX=>21*sw, :locY=>7*sh, :width=>40, :height=>15*sh});
	        addLayer(accuracyLayer);
	        
	        clockLayer = new Ui.Layer({:locX=>35*sw, :locY=>1.5*sh, :width=>30*sw, :height=>12.5*sh});
	        addLayer(clockLayer);
	        
	        batteryLayer = new Ui.Layer({:locX=>39.5*sw, :locY=>15*sh, :width=>23*sw, :height=>7*sh});
	        addLayer(batteryLayer);
	        
	        heartRateLayer = new Ui.Layer(top);
	        
	        //glideTimeLayer = new Ui.Layer(upperRight);
	        //rescaleLayerPos(glideTimeLayer);
	        //addLayer(glideTimeLayer);
	        
	        //strideLengthLayer = new Ui.Layer(lowerRight);
	        //rescaleLayerPos(strideLengthLayer);
	        //addLayer(strideLengthLayer);
	        
	        distanceLayer = new Ui.Layer(upperLeft);
	        rescaleLayerPos(distanceLayer);
	        addLayer(distanceLayer);
	        
	        timerLayer = new Ui.Layer(upperRight);
	        rescaleLayerPos(timerLayer);
	        addLayer(timerLayer);
	        
	        speedLayer = new Ui.Layer(lowerLeft);
	        rescaleLayerPos(speedLayer);
	        addLayer(speedLayer);
	        
	        energyExpenditureLayer = new Ui.Layer(lowerRight);
	        rescaleLayerPos(energyExpenditureLayer);
	        addLayer(energyExpenditureLayer);
	        
	        trainingEffectLayer = new Ui.Layer(bottomLeft);
	        addLayer(trainingEffectLayer);
	        
	        caloriesLayer = new Ui.Layer(bottomRight);
	        addLayer(caloriesLayer);
    	}
    	if (status == Controller.STAT_STD) {	  
    		System.println("View status changed: " +  status);
	        
	        heartRateLayer = new Ui.Layer(full);
	        addLayer(heartRateLayer);
	        
	        //glideTimeLayer = new Ui.Layer(upperRight);
	        //rescaleLayerPos(glideTimeLayer);
	        //addLayer(glideTimeLayer);
	        
	        //strideLengthLayer = new Ui.Layer(lowerRight);
	        //rescaleLayerPos(strideLengthLayer);
	        //addLayer(strideLengthLayer);

	        distanceLayer = new Ui.Layer(upperLeft);
	        rescaleLayerPos(distanceLayer);
	        addLayer(distanceLayer);
	        
	        timerLayer = new Ui.Layer(upperRight);
	        rescaleLayerPos(timerLayer);
	        addLayer(timerLayer);
	        
	        speedLayer = new Ui.Layer(lowerLeft);
	        rescaleLayerPos(speedLayer);
	        addLayer(speedLayer);
	        
	        energyExpenditureLayer = new Ui.Layer(lowerRight);
	        rescaleLayerPos(energyExpenditureLayer);
	        addLayer(energyExpenditureLayer);
	        
	        trainingEffectLayer = new Ui.Layer(bottomLeft);
	        addLayer(trainingEffectLayer);
	        
	        caloriesLayer = new Ui.Layer(bottomRight);
	        addLayer(caloriesLayer);
	        
    		viewNameLayer = new Ui.Layer(bottom);
    		addLayer(viewNameLayer);
    	}
    	if (status == Controller.STAT_LAP){
    	
	        heartRateLayer = new Ui.Layer(full);
	        addLayer(heartRateLayer);
	        
	        lapAvgCadenceLayer = new Ui.Layer(upperLeft);
	        rescaleLayerPos(lapAvgCadenceLayer);
	        addLayer(lapAvgCadenceLayer);
	        
	        lapAvgGlideTimeLayer = new Ui.Layer(upperRight);
	        rescaleLayerPos(lapAvgGlideTimeLayer);
	        addLayer(lapAvgGlideTimeLayer);
	        
    		lapAvgSpeedLayer = new Ui.Layer(lowerLeft);
	        rescaleLayerPos(lapAvgSpeedLayer);
	        addLayer(lapAvgSpeedLayer);
	        
	        lapAvgStrideLengthLayer = new Ui.Layer(lowerRight);
	        rescaleLayerPos(lapAvgStrideLengthLayer);
	        addLayer(lapAvgStrideLengthLayer);
	        
	        lapTimeLayer = new Ui.Layer(bottomLeft);
	        addLayer(lapTimeLayer);
	        
	        lapDistanceLayer = new Ui.Layer(bottomRight);
	        addLayer(lapDistanceLayer);
	        
    		viewNameLayer = new Ui.Layer(bottom);
    		addLayer(viewNameLayer);
    	}
    	if (status == Controller.STAT_TOTAL) {	  
    		System.println("View status changed: " +  status);
    		
	        iconsConnectedLayer = new Ui.Layer({:locX=>64*sw, :locY=>8.5*sh, :width=>30, :height=>30});
	        addLayer(iconsConnectedLayer);
	        
	        accuracyLayer = new Ui.Layer({:locX=>21*sw, :locY=>7*sh, :width=>40, :height=>15*sh});
	        addLayer(accuracyLayer);
	        
	        clockLayer = new Ui.Layer({:locX=>35*sw, :locY=>1.5*sh, :width=>30*sw, :height=>12.5*sh});
	        addLayer(clockLayer);
	        
	        batteryLayer = new Ui.Layer({:locX=>39.5*sw, :locY=>15*sh, :width=>23*sw, :height=>7*sh});
	        addLayer(batteryLayer);
	        
	        heartRateLayer = new Ui.Layer(top);
	        
	        totalAvgCadenceLayer = new Ui.Layer(upperLeft);
	        rescaleLayerPos(totalAvgCadenceLayer);
	        addLayer(totalAvgCadenceLayer);
	        
	        totalAvgGlideTimeLayer = new Ui.Layer(upperRight);
	        rescaleLayerPos(totalAvgGlideTimeLayer);
	        addLayer(totalAvgGlideTimeLayer);
	        
	        totalAvgSpeedLayer = new Ui.Layer(lowerLeft);
	        rescaleLayerPos(totalAvgSpeedLayer);
	        addLayer(totalAvgSpeedLayer);
	        
	        totalAvgStrideLengthLayer = new Ui.Layer(lowerRight);
	        rescaleLayerPos(totalAvgStrideLengthLayer);
	        addLayer(totalAvgStrideLengthLayer);
	        
	        maxSpeedLayer = new Ui.Layer(bottomLeft);
	        addLayer(maxSpeedLayer);
	        
	        maxHeartRateLayer = new Ui.Layer(bottomRight);
	        addLayer(maxHeartRateLayer);
	        
    		viewNameLayer = new Ui.Layer(bottom);
    		addLayer(viewNameLayer);
    	}
    }
    
    	function addLayerIfHidden(layer){
    		if (getLayerIndex(layer) == -1) {
    			addLayer(layer);
    		}
    	}
    
    	// Scaling functions
    	
    	// Adjust position of layer to screen size
	    function rescaleLayerPos(layer){
	    	layer.setX(scale(layer.getX()));
	    	layer.setY(scale(layer.getY()));	
	    }
	    
	    // Scale any position of standard screen to present screen size
	    function scale(pos){
	    	var devicePos = pos * screenSizeScale;
	    	return devicePos.toNumber();
	    }
	    
	    // Returns text size (number) which fits to screen size
	    function rescaleStdFont(){
	    	var fontSize = Gfx.FONT_XTINY;	// Start with smallest font size
	    	var fontSizeScaleFactor = Gfx.getFontHeight(fontSize) / stdFontHeight;
	    	while (fontSizeScaleFactor < screenSizeScale) {
	    		fontSize++;
	    		fontSizeScaleFactor = Gfx.getFontHeight(fontSize).toFloat() / stdFontHeight;
	    	}
	    	stdFont = fontSize;
	    	stdFontHeight = Gfx.getFontHeight(stdFont);
	    }


    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        System.println("onShow SkatingView");
        System.println("Steps at onShow: " + ActivityMonitor.getInfo().steps);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
        WatchUi.requestUpdate();
        System.println("Steps at onHide: " + ActivityMonitor.getInfo().steps);
    }
    
    
    
    var sleepTimer;
    
    function onEnterSleep(){
    	WatchUi.requestUpdate();
    	System.println("Entering sleep mode");
    	sleepTimer = new Timer.Timer();
		sleepTimer.start(method(:updateDuringSleep), 1000, false);
    }
    
    function updateDuringSleep(){
    	WatchUi.requestUpdate();
    	System.println("Sleeping power");
    }
    
    function onExitSleep(){
    	sleepTimer.stop();
    }
    
    
    

    // Update the view
    function onUpdate(dc) {
    	
        System.println("onUpdate SkatingView");
        dc.setColor(foregroundColor, backgroundColor);
        dc.clear();
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    	dc.setColor(foregroundColor, backgroundColor);
    	dc.clear();
        
        if (status == Controller.STAT_INIT){
        	updateInit();
        }
        
        if (status == Controller.STAT_STD){
        	updateStd();
        }
        
        if (status == Controller.STAT_LAP){
        	updateLap();
        }
        
        if (status == Controller.STAT_TOTAL){
        	updateTotal();
        }
		
    }
    
	    function updateInit(){
	    	updateGrid(gridLayer.getDc());
	        updateConnections(iconsConnectedLayer.getDc());
	        updatePositionAccuracy(accuracyLayer.getDc());
	        updateBattery(batteryLayer.getDc());
	        updateClock(clockLayer.getDc());
	    	updateHeartRateLayer(heartRateLayer.getDc());
	    	updateSpeed(speedLayer.getDc());
	        //updateGlideTime(glideTimeLayer.getDc());
	        //updateCadence(cadenceLayer.getDc());
	        //updateStrideLength(strideLengthLayer.getDc());
	        updateEnergyExpenditure(energyExpenditureLayer.getDc());
	        updateTrainingEffect(trainingEffectLayer.getDc());
	        updateCaloriesLayer(caloriesLayer.getDc());
	        updateTimerLayer(timerLayer.getDc());
			updateElapsedDistance(distanceLayer.getDc());
	    }
	    
	    function updateStd(){
	    	updateGrid(gridLayer.getDc());
	    	updateHeartRateLayer(heartRateLayer.getDc());
	    	updateSpeed(speedLayer.getDc());
	        //updateGlideTime(glideTimeLayer.getDc());
	        //updateCadence(cadenceLayer.getDc());
	        //updateStrideLength(strideLengthLayer.getDc());
	        updateEnergyExpenditure(energyExpenditureLayer.getDc());
	        updateTrainingEffect(trainingEffectLayer.getDc());
	        updateCaloriesLayer(caloriesLayer.getDc());
	        updateTimerLayer(timerLayer.getDc());
			updateElapsedDistance(distanceLayer.getDc());
	        updateViewNameLayer(viewNameLayer.getDc());
	    }
	    
	    function updateLap(){
	    	updateGrid(gridLayer.getDc());
	    	updateHeartRateLayer(heartRateLayer.getDc());
	    	updateLapAvgSpeedLayer(lapAvgSpeedLayer.getDc());
			updateLapAvgCadenceLayer(lapAvgCadenceLayer.getDc());
			updateLapAvgGlideTimeLayer(lapAvgGlideTimeLayer.getDc());
			updateLapAvgStrideLengthLayer(lapAvgStrideLengthLayer.getDc());
			updateLapTimeLayer(lapTimeLayer.getDc());
			updateLapDistanceLayer(lapDistanceLayer.getDc());
	        updateViewNameLayer(viewNameLayer.getDc());
	    }
	    
	    function updateTotal(){
	    	updateGrid(gridLayer.getDc());
	        updateConnections(iconsConnectedLayer.getDc());
	        updatePositionAccuracy(accuracyLayer.getDc());
	        updateBattery(batteryLayer.getDc());
	        updateClock(clockLayer.getDc());
	    	updateHeartRateLayer(heartRateLayer.getDc());
	    	updateTotalAvgSpeedLayer(totalAvgSpeedLayer.getDc());
			updateTotalAvgGlideTimeLayer(totalAvgGlideTimeLayer.getDc());
	        updateTotalAvgCadenceLayer(totalAvgCadenceLayer.getDc());
	        updateTotalAvgStrideLengthLayer(totalAvgStrideLengthLayer.getDc());
	        updateMaxSpeedLayer(maxSpeedLayer.getDc());
	        updateMaxHeartRateLayer(maxHeartRateLayer.getDc());
	        //updateTimerLayer(timerLayer.getDc());
	        //updateElapsedDistance(distanceLayer.getDc());
	        updateViewNameLayer(viewNameLayer.getDc());
	    }
    
    // --- Draw helper functions ---
	
		// Return largest possible font for DC
		function maxFontDc(dc,text,isNumber) {
	    	return maxFont(dc,text,isNumber,dc.getWidth(),dc.getHeight());			
		}
		
		function maxFont(dc,text,isNumber,width,height) {
			if (text == "") {
				return 0;
			}
			var font = Gfx.FONT_XTINY;						// Start with smallest font size
			var textStr = (text instanceof Toybox.Lang.String) ? text : text.toString();
			var textDim = dc.getTextDimensions(textStr, font);
	    	while (width >= textDim[0] && height >= textDim[1]) {
	    		font++;
	    		if (font == 9){
	    			textDim[0] = width;
	    			textDim[1] = height;
	    		}
	    		textDim = dc.getTextDimensions(textStr, font);
	    	}
	    	if (!isNumber) {
	    		font = (font > 4) ? 4 : font;					// Check maximum font size
	    	}
	    	return (font > 0) ? font-1 : font;				// Check mimimum font size			
		}
		
		// Center font vertically
		// Returns y value for vertical font position
		// height can be dc.getHeight()
		function centerFontVert(height,font){
			var yPos = (height - Gfx.getFontHeight(font)) / 2.0;
	        return (yPos < 0.0) ? 0 : yPos;
		}
	    
	    function drawValueUnit(dc, valueStr, unitStr)  {
	    	dc.setColor(foregroundColor, backgroundColor);
	    	dc.clear();
			var dcW = dc.getWidth();
	        var dcH = dc.getHeight();
	        var spacer = dcW/20.0;
		        
	        // Value 
	        var fontValue = maxFont(dc, valueStr, true, dcW*3.0/4, dcH);
	        var fontValueWidth = dc.getTextDimensions(valueStr, fontValue)[0];
	        
	        // Unit 
	        if (unitStr != null){
	        	var fontUnit = maxFont(dc, unitStr , false, dcW - fontValueWidth - spacer, dcH);
		        fontUnit = (fontUnit > 0) ? fontUnit-1 : fontUnit;
		        var fontUnitWidth = dc.getTextDimensions(unitStr, fontUnit)[0];
		        fontValueWidth = dcW - fontUnitWidth - spacer;  // May be larger than 3/4 of with if unit width is small or none
	        	dc.drawText(dcW, centerFontVert(dcH,fontUnit), fontUnit, unitStr, Gfx.TEXT_JUSTIFY_RIGHT);	
	        }
	        else {
	        	fontValueWidth = dcW;
	        }
	        
	        fontValue = maxFont(dc, valueStr, true, fontValueWidth, dcH);  // Check if more space is avaible
	        dc.drawText(fontValueWidth/2, centerFontVert(dcH,fontValue),fontValue, valueStr, Gfx.TEXT_JUSTIFY_CENTER);	
	    }
	    
	    function drawValueUnitTitle(dc, valueStr, unitStr, titleStr)  {
	    	dc.setColor(foregroundColor, backgroundColor);
	    	dc.clear();
			var dcW = dc.getWidth();
	        var dcH = dc.getHeight();
	        var spacer = dcW/20.0;
	        
	        // Title
	        var fontTitle = Gfx.FONT_XTINY;
	        var fontTitleHeight = dc.getTextDimensions(titleStr, fontTitle)[1];
	        dc.drawText(dcW/2, 0, fontTitle, titleStr, Gfx.TEXT_JUSTIFY_CENTER);	
	        
	        // Value 
	        var heightValue = dcH - fontTitleHeight;
	        var fontValue = maxFont(dc, valueStr, true, dcW*3.0/4, heightValue);
	        var fontValueWidth = dc.getTextDimensions(valueStr, fontValue)[0];
	        
	        // Unit 
	        if (unitStr != null){
	        	var fontUnit = maxFont(dc, unitStr , false, dcW - fontValueWidth - spacer, heightValue);
		        fontUnit = (fontUnit > 0) ? fontUnit-1 : fontUnit;
		        var fontUnitWidth = dc.getTextDimensions(unitStr, fontUnit)[0];
		        fontValueWidth = dcW - fontUnitWidth - spacer;  // May be larger than 3/4 of with if unit width is small or none
	        	dc.drawText(dcW, centerFontVert(heightValue,fontUnit)+fontTitleHeight, fontUnit, unitStr, Gfx.TEXT_JUSTIFY_RIGHT);	
	        }
	        else {
	        	fontValueWidth = dcW;
	        }
	        
	        fontValue = maxFont(dc, valueStr, true, fontValueWidth, heightValue);  // Check if more space is avaible
	        dc.drawText(fontValueWidth/2, centerFontVert(heightValue,fontValue)+fontTitleHeight,fontValue, valueStr, Gfx.TEXT_JUSTIFY_CENTER);	
	    }
    
    
    // --- Update layer functions ---
    
    
    function updateHeartRateLayer(dc) {
    	dc.setColor(foregroundColor, Gfx.COLOR_TRANSPARENT);
		dc.clear();
		
		var dcW = dc.getWidth();
        var dcH = dc.getHeight();
        
		var maxHRFontHeight = dcH/6;
		var posYHR = dcH/4 - maxHRFontHeight;
        
        var heartRateText = "---";
	    var lastHeartRate = 0;
		var currentHeartRate = Activity.getActivityInfo().currentHeartRate;
		var heartRate = 0;
		if(currentHeartRate != null) {
			heartRateText = currentHeartRate.toString();
			heartRate = currentHeartRate;
		}
		else {
			var heartRateHistory = ActivityMonitor.getHeartRateHistory(1, true);
			var heartRateSample = heartRateHistory.next();
			lastHeartRate = heartRateSample.heartRate;
			if(heartRateSample == ActivityMonitor.INVALID_HR_SAMPLE){
				heartRateText = "---";
			}
			else{
				heartRateText = lastHeartRate.toString();
				heartRate = lastHeartRate;
			}
		}
		
		var iconWidth = dc.getTextDimensions(ICON_HEART, customIcons)[0];
		var iconHeight = dc.getTextDimensions(ICON_HEART, customIcons)[1];
		var spacer = dcW/40.0;
        
		var hrWidth = dcW-iconWidth-spacer;
    	var fontHR = maxFont(dc, heartRateText, true, hrWidth, maxHRFontHeight);
        var fontHRWidth = dc.getTextDimensions(heartRateText, fontHR)[0];
        var fontHRHeight = dc.getTextDimensions(heartRateText, fontHR)[1];
        
        var xPos = dcW/2 - spacer - iconWidth/2 - fontHRWidth/2;
        
        dc.drawText(xPos, centerFontVert(maxHRFontHeight,customIcons)+posYHR,customIcons, ICON_HEART, Gfx.TEXT_JUSTIFY_CENTER);	
        dc.drawText(dcW/2, centerFontVert(maxHRFontHeight,fontHR)+posYHR,fontHR, heartRateText, Gfx.TEXT_JUSTIFY_CENTER);	
        
        // Heart rate zones
        
        var genericZoneInfo = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        
        
        var halfSpace = 1; // degree
        var zoneLenght = 18; // degree
        var startLeft = 90+2.5*zoneLenght;
        var endRight = 90-2.5*zoneLenght;
        var zoneColors = [Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN, Gfx.COLOR_ORANGE, Gfx.COLOR_RED];
        for( var i = 1; i < genericZoneInfo.size(); i += 1 ) {
        	dc.setColor(zoneColors[i-1], Gfx.COLOR_TRANSPARENT);
        	if (heartRate >= genericZoneInfo[i-1] && heartRate < genericZoneInfo[i]){
        		dc.drawText(xPos, centerFontVert(maxHRFontHeight,customIcons)+posYHR,customIcons, ICON_HEART, Gfx.TEXT_JUSTIFY_CENTER);	
        		dc.setPenWidth(posYHR/2);
        	}
        	else {
        		dc.setPenWidth(posYHR/4);
        	}
        	dc.drawArc(sw*50, sh*50, sw*50-sw*4, Gfx.ARC_CLOCKWISE, startLeft-halfSpace-zoneLenght*(i-1), startLeft+halfSpace-zoneLenght*i);
        }
        
        // Draw current heart rate marker
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(posYHR/2+2);
    	
    	var markerPos = startLeft - zoneLenght.toFloat() * 5 * (1 - (genericZoneInfo[5].toFloat() - heartRate.toFloat()) / (genericZoneInfo[5].toFloat() - genericZoneInfo[0].toFloat()));
    	markerPos = (markerPos > startLeft) ? startLeft : markerPos;
    	markerPos = (markerPos < endRight) ? endRight : markerPos;
    	
    	dc.drawArc(sw*50, sh*50, sw*50-sw*4, Gfx.ARC_CLOCKWISE, markerPos+1, markerPos-1);
    }
    
    
    // Speed
    
    var speed = "-";
    var speedUnit = "km/h";
    var speedTitle = WatchUi.loadResource(Rez.Strings.label_speed);
    
	function updateSpeed(dc){
		var currentSpeed = Activity.getActivityInfo().currentSpeed;
		if (currentSpeed != null && currentSpeed != 0 && status != Controller.STAT_INIT) {
			speed = (currentSpeed * 3.6).format("%.1f");
			speedUnit = "km/h";
		}
		drawValueUnitTitle(dc, speed, speedUnit, speedTitle);
	}
	
    function updateLapAvgSpeedLayer(dc){
		var currentSpeed = _fitManager.getLapAvgVelocity();
		if (currentSpeed != null && currentSpeed != 0 && status != Controller.STAT_INIT) {
			speed = (currentSpeed * 3.6).format("%.1f");
			speedUnit = "km/h";
		}
		drawValueUnitTitle(dc, speed, speedUnit, speedTitle);
	}
	
	function updateTotalAvgSpeedLayer(dc){
		var currentSpeed = _fitManager.getTotalAvgVelocity();
		if (currentSpeed != null && currentSpeed != 0 && status != Controller.STAT_INIT) {
			speed = (currentSpeed * 3.6).format("%.1f");
			speedUnit = "km/h";
		}
		drawValueUnitTitle(dc, speed, speedUnit, speedTitle);
	}
		
	
	// Elapsed distance
    
    var distance = "-";
    var distanceUnit = "m";
    var distanceTitle = WatchUi.loadResource(Rez.Strings.label_distance);
    
    function updateElapsedDistance(dc){    
        var elapsedDistance = Activity.getActivityInfo().elapsedDistance;
		drawDistance(dc,elapsedDistance);
    }
    
    function updateLapDistanceLayer(dc){  
		var elapsedDistance = _fitManager.getLapDistance();
		drawDistance(dc,elapsedDistance);
    }
    
    	function drawDistance(dc,elapsedDistance){  
	        System.println("Elapsed distance: " + elapsedDistance);
	        if (elapsedDistance != null && elapsedDistance != 0 && status != Controller.STAT_INIT){
	        	if (elapsedDistance < 1000){
	        		distance = elapsedDistance.format("%i");
	        		distanceUnit = "m";
	        	}
	        	else if (elapsedDistance < 10000){
	        		distance = (elapsedDistance/1000.0).format("%.2f");
	        		distanceUnit = "km";
	        	}
	        	else {
	        		distance = (elapsedDistance/1000.0).format("%.1f");
	        		distanceUnit = "km";
	        	}
			}
			drawValueUnitTitle(dc, distance, distanceUnit, distanceTitle);	
    	}
    	
    	
    // Energy Expenditure
    
    var energyExpenditure = "-";
    var energyExpenditureUnit = "kcal/min";
    var energyExpenditureTitle = WatchUi.loadResource(Rez.Strings.label_energy_expenditure);
    
    function updateEnergyExpenditure(dc) {
        if (Activity.getActivityInfo().energyExpenditure != 0.0 && Activity.getActivityInfo().energyExpenditure != null && status != Controller.STAT_INIT) {
			energyExpenditure = Activity.getActivityInfo().energyExpenditure.format("%.1f");
			energyExpenditureUnit = "kcal/min";
		}
        drawValueUnitTitle(dc, energyExpenditure, energyExpenditureUnit, energyExpenditureTitle);
    }
    
    
    // Training Effect
    
    var trainingEffect = "-";
    var trainingEffectUnit = " ";
    var trainingEffectTitle = WatchUi.loadResource(Rez.Strings.label_training_effect);
    
	function updateTrainingEffect(dc){
        if (Activity.getActivityInfo().trainingEffect != 0.0 && Activity.getActivityInfo().trainingEffect != null && status != Controller.STAT_INIT){
			trainingEffect = Activity.getActivityInfo().trainingEffect.format("%.1f");
			trainingEffectUnit = " ";
		}
        drawValueUnitTitle(dc, trainingEffect, trainingEffectUnit, trainingEffectTitle);
	}
	
	
	// Calories
	
	var calories = "-";
    var caloriesUnit = "kcal";
    var caloriesTitle = WatchUi.loadResource(Rez.Strings.label_calories);
    
	function updateCaloriesLayer(dc){
        if (Activity.getActivityInfo().calories != 0.0 && Activity.getActivityInfo().calories != null && status != Controller.STAT_INIT){
			calories = Activity.getActivityInfo().calories.format("%i");
			caloriesUnit = "kcal";
		}
        drawValueUnitTitle(dc, calories, caloriesUnit, caloriesTitle);
	}
    	
    	
   	// Glide time
    
	var glideTime = "-";
    var glideTimeUnit = "s";
    var glideTimeTitle = WatchUi.loadResource(Rez.Strings.label_glide_time);
    
    function updateGlideTime(dc){ 
        if (_fitManager.getGlideTime() != 0.0 && status != Controller.STAT_INIT){
			glideTime = _fitManager.getGlideTime().format("%.1f");
			glideTimeUnit = "s";
		}
        drawValueUnitTitle(dc, glideTime, glideTimeUnit, glideTimeTitle);
    }
    
	function updateLapAvgGlideTimeLayer(dc){
        var avgGT = _fitManager.getLapAvgGlideTime();
        
        if (avgGT != 0.0 && avgGT != null && status != Controller.STAT_INIT){
        	if (avgGT < 10){
				glideTime = avgGT.format("%.2f");
				glideTimeUnit = "s";
			}
			else {
				glideTime = avgGT.toNumber().format("%.1f");
				glideTimeUnit = "s";
			}
		}
        drawValueUnitTitle(dc, glideTime, glideTimeUnit, glideTimeTitle);
    }
    
    function updateTotalAvgGlideTimeLayer(dc){
        var avgGT = _fitManager.getTotalAvgGlideTime();
        
        if (avgGT != 0.0 && avgGT != null && status != Controller.STAT_INIT){
        	if (avgGT < 100){
				glideTime = avgGT.format("%.2f");
				glideTimeUnit = "s";
			}
			else {
				glideTime = avgGT.toNumber().format("%.1f");
				glideTimeUnit = "s";
			}
		}
        drawValueUnitTitle(dc, glideTime, glideTimeUnit, glideTimeTitle);
    }
    
    
    // Cadence
    
	var cadence = "-";
    var cadenceUnit = "spm";
    var cadenceTitle = WatchUi.loadResource(Rez.Strings.label_cadence);
    
    function updateCadence(dc){ 
        if (_fitManager.getCadence() != 0.0 && status != Controller.STAT_INIT){
			cadence = _fitManager.getCadence().toNumber().format("%i");
			cadenceUnit = "spm";
		}
        drawValueUnitTitle(dc, cadence, cadenceUnit, cadenceTitle);
    }
    
	function updateLapAvgCadenceLayer(dc){
        var avgCad = _fitManager.getLapAvgCadence();
        
        if (avgCad != 0.0 && avgCad != null && status != Controller.STAT_INIT){
        	if (avgCad < 100){
				cadence = avgCad.format("%.1f");
				cadenceUnit = "spm";
			}
			else {
				cadence = avgCad.toNumber().format("%i");
				cadenceUnit = "spm";
			}
		}
        
        drawValueUnitTitle(dc, cadence, cadenceUnit, cadenceTitle);
    }
    
    function updateTotalAvgCadenceLayer(dc){
        var avgCad = _fitManager.getTotalAvgCadence();
        
        if (avgCad != 0.0 && avgCad != null && status != Controller.STAT_INIT){
        	if (avgCad < 100){
				cadence = avgCad.format("%.1f");
				cadenceUnit = "spm";
			}
			else {
				cadence = avgCad.toNumber().format("%i");
				cadenceUnit = "spm";
			}
		}
        
        drawValueUnitTitle(dc, cadence, cadenceUnit, cadenceTitle);
    }
    
    
    // Stride length
    
    var strideLength = "-";
    var strideLengthUnit = "m";
    var strideLengthTitle = WatchUi.loadResource(Rez.Strings.label_stride_length);
    
    function updateStrideLength(dc){        
		var currentStrideLength =  _fitManager.getStrideLength();
        
        if (currentStrideLength != 0.0 && currentStrideLength != null && status != Controller.STAT_INIT){
			strideLength = currentStrideLength.format("%.1f");
        	strideLengthUnit = "m";
		}
        drawValueUnitTitle(dc, strideLength, strideLengthUnit, strideLengthTitle);
    }
    
	function updateLapAvgStrideLengthLayer(dc){        
        var currentStrideLength = _fitManager.getLapAvgStrideLength();
        
        if (currentStrideLength != 0.0 && currentStrideLength != null && status != Controller.STAT_INIT){
			strideLength = currentStrideLength.format("%.2f");
        	strideLengthUnit = "m";
		}
        drawValueUnitTitle(dc, strideLength, strideLengthUnit, strideLengthTitle);
    }    
    
    function updateTotalAvgStrideLengthLayer(dc){        
        var currentStrideLength = _fitManager.getTotalAvgStrideLength();
        
        if (currentStrideLength != 0.0 && currentStrideLength != null && status != Controller.STAT_INIT){
			strideLength = currentStrideLength.format("%.2f");
        	strideLengthUnit = "m";
		}
        drawValueUnitTitle(dc, strideLength, strideLengthUnit, strideLengthTitle);
    }    
    
    
    // Max. Speed
    
	var maxSpeed = "-";
    var maxSpeedUnit = "km/h";
    var maxSpeedTitle = WatchUi.loadResource(Rez.Strings.label_speed);
    
    function updateMaxSpeedLayer(dc){
        if (Activity.getActivityInfo().maxSpeed != 0.0 && Activity.getActivityInfo().maxSpeed != null && status != Controller.STAT_INIT){
			maxSpeed = (Activity.getActivityInfo().maxSpeed * 3.6).format("%.1f");
			maxSpeedUnit = "km/h";
		}
        drawValueUnitTitle(dc, maxSpeed, maxSpeedUnit, maxSpeedTitle);
    }
    
    
    // Max. Heart Rate
    
	var maxHeartRate = "-";
    var maxHeartRateUnit = "bpm";
    var maxHeartTitle = WatchUi.loadResource(Rez.Strings.label_heart_rate);
    
    function updateMaxHeartRateLayer(dc){
        if (Activity.getActivityInfo().maxHeartRate != 0.0 && Activity.getActivityInfo().maxHeartRate != null && status != Controller.STAT_INIT){
			maxHeartRate = Activity.getActivityInfo().maxHeartRate.format("%i");
			maxHeartRateUnit = "bpm";
		}
        drawValueUnitTitle(dc, maxHeartRate, maxHeartRateUnit, maxHeartTitle);
    }
    
	    
	// Timer
	
    var timerTitle = WatchUi.loadResource(Rez.Strings.label_timer);
	    
	function updateTimerLayer(dc) {
		var activityTimeSec = Activity.getActivityInfo().elapsedTime/1000;
		if (activityTimeSec > 0 && status != Controller.STAT_INIT) {
			drawTimerLayer(dc,activityTimeSec);
		}
		else {
			drawValueUnitTitle(dc, "-", " ", timerTitle);
		}
	}
	
	
	function updateLapTimeLayer(dc){
		var activityTimeSec = (_fitManager.getLapTime()/1000).toNumber();
		if (activityTimeSec > 0 && status != Controller.STAT_INIT) {
			drawTimerLayer(dc,activityTimeSec);
		}
		else {
			drawValueUnit(dc, "Lap-" + timerTitle, " ");
		}
	}
	
		function drawTimerLayer (dc,time) {
			dc.setColor(foregroundColor, backgroundColor);
			dc.clear();
			
			var dcW = dc.getWidth();
	        var dcH = dc.getHeight();
	        
	        // Title
	        var fontTitle = Gfx.FONT_XTINY;
	        var fontTitleHeight = dc.getTextDimensions(timerTitle, fontTitle)[1];
	        dc.drawText(dcW/2, 0, fontTitle, timerTitle, Gfx.TEXT_JUSTIFY_CENTER);	
	        
	        // Value 
	        var heightValue = dcH - fontTitleHeight;
			
			var activityTimeSec = time;
			var hr = activityTimeSec/3600; 
			
			if (hr > 0) {
				var hourWidth = dcW/6.0;
				var hourHeight = heightValue/2.0;
				var spacer = dcW/10.0;
				var hrStr = hr.toString();
	        	var fontH = maxFont(dc, hrStr, true, hourWidth, hourHeight);
		        var fontHWidth = dc.getTextDimensions(hrStr, fontH)[0];
		        
		        var msStr = toMS(activityTimeSec).toString();
				var msWidth = dcW-hourWidth-spacer;
	        	var fontMS = maxFont(dc, msStr, true, msWidth, heightValue);
		        var fontMSWidth = dc.getTextDimensions(msStr, fontH)[0];
		        
		        var offsetX = (dcW-(fontMSWidth+spacer+hourWidth))/2;
		        
		        dc.drawText(fontHWidth/2+offsetX, centerFontVert(hourHeight,fontH)+fontTitleHeight,fontH, hrStr, Gfx.TEXT_JUSTIFY_CENTER);	
		        dc.drawText(fontMSWidth/2+spacer+hourWidth+offsetX, centerFontVert(heightValue,fontMS)+fontTitleHeight,fontMS, msStr, Gfx.TEXT_JUSTIFY_CENTER);	
	        }
	        else {
	        	drawValueUnitTitle(dc,toMS(activityTimeSec).toString(),null,timerTitle);
	        }
		}
	
		function toHMS(secs) {
			var hr = secs/3600;
			var min = (secs-(hr*3600))/60;
			var sec = secs%60;
			return hr.format("%02d")+":"+min.format("%02d")+":"+sec.format("%02d");
		}
		
		function toMS(secs) {
			var hr = secs/3600;
			var min = (secs-(hr*3600))/60;
			var sec = secs%60;
			return min.format("%02d")+":"+sec.format("%02d");
		}
		
	
	
	
	// General layers:
	
	
    
    function updateClock(dc){
        dc.setColor(foregroundColor, backgroundColor);	
    	dc.clear();
    	
    	var clockTime = System.getClockTime();
        var timeStringHour = clockTime.hour.format("%02d");
        var timeStringMin = clockTime.min.format("%02d");
        var timeStr = Lang.format("$1$:$2$", [timeStringHour, timeStringMin]);
        var font = maxFontDc(dc,timeStr,true);
	    dc.drawText(dc.getWidth()/2, 0, font, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
    }
	
	function updateConnections(dc) {
        dc.setColor(foregroundColor, backgroundColor);	
    	dc.clear();
    	
    	if (Sys.getDeviceSettings().phoneConnected) {
	    	dc.setColor(foregroundColor, backgroundColor);
	    	dc.drawText(dc.getWidth()-1, 0, iconsConnected, ICON_CONNECTED_PHONE, Gfx.TEXT_JUSTIFY_RIGHT); 
    	}
    }
    
    function updatePosition(info) {
    	updatePositionAccuracy(accuracyLayer.getDc());
    }
    
    	function updatePositionAccuracy(dc){
    		var info = Position.getInfo();
    		
        	dc.setColor(foregroundColor, backgroundColor);	
    		dc.clear();
	        var dcW = dc.getWidth();
	        var dcH = dc.getHeight();
	        
	        var font = Gfx.FONT_XTINY;
	        var fontHeight = Gfx.getFontHeight(font);
	        
	        if (info.accuracy < 2) {
	        	dc.setColor(Gfx.COLOR_RED, backgroundColor);
	        }
	        else {
	        	dc.setColor(foregroundColor, backgroundColor);
	        }
	        
        	dc.drawText(dcW*0.5, dcH-fontHeight, font, "GPS", Gfx.TEXT_JUSTIFY_CENTER);	
        	
	        var pen = 3;
	        dc.setPenWidth(pen);
	        
	        var fontWidth = dc.getTextDimensions("GPS", font)[0];
	        var margin = (dcW - fontWidth) / 2 + 4;
	        var step = (fontWidth - pen) / 4 - 1;
	        var heightStep = (dcH-fontHeight) / 5;
	        
	        dc.drawLine(margin, heightStep*4+1, margin, dcH-1-fontHeight);	
	        if (info.accuracy < 1) { dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor); } 
	        dc.drawLine(margin+step, heightStep*3+1, margin+step, dcH-1-fontHeight);  
	        if (info.accuracy < 2) { dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor); } 
	        dc.drawLine(margin+2*step, heightStep*2+1, margin+2*step, dcH-1-fontHeight);  
	        if (info.accuracy < 3) { dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor); } 
	        dc.drawLine(margin+3*step, heightStep+1, margin+3*step, dcH-1-fontHeight); 
	        if (info.accuracy < 4) { dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor); }
	        dc.drawLine(margin+4*step, 1, margin+4*step, dcH-1-fontHeight);
    	}
    
    function updateBattery(dc) {
	    dc.setColor(foregroundColor, backgroundColor);
    	dc.clear();
    	
		var batteryX = scale(29);
		var batteryY = scale(3.8);
		var systemStats = System.getSystemStats();
		var battery = systemStats.battery;
		var batteryBarLength = scale(0.16 * battery);
        var batteryTextHeight = dc.getTextDimensions("0", Gfx.FONT_XTINY)[1];
        var dcH = dc.getHeight();
        
        // Draw battery status text
        if (battery < 100){
	        dc.setColor(foregroundColor, backgroundColor);
		    dc.drawText(0, dcH-batteryTextHeight, Gfx.FONT_XTINY, battery.format("%d") + "%", Gfx.TEXT_JUSTIFY_LEFT);
	    }
	    else {
	    	batteryX = scale(18);
	    }	
		
		// Outer rectangle
        dc.setColor(foregroundColor, backgroundColor);
        dc.drawRectangle(batteryX, batteryY, scale(20), scale(10));
        dc.drawRectangle(batteryX+scale(20), batteryY + scale(2), scale(4), scale(6));
		
		// Inner filling
		dc.setColor(Gfx.COLOR_DK_GREEN, backgroundColor);
		if (battery < 90 + lowBatteryThreshold/10) {
			dc.setColor(foregroundColor, backgroundColor);			
		}
		if (battery < 20 + lowBatteryThreshold/5*4) {
			dc.setColor(Gfx.COLOR_ORANGE, backgroundColor);			
		}
        dc.fillRectangle(batteryX + scale(2), batteryY + scale(2), batteryBarLength, scale(6));
        
		if (battery < lowBatteryThreshold) {
			// Warning Text with Remaining Battery Status
    		dc.clear();
			dc.setColor(Gfx.COLOR_RED, backgroundColor);	
	    	dc.drawText(6, 0, customIcons, ICON_BATTERY, Gfx.TEXT_JUSTIFY_LEFT); 
	        dc.drawText(batteryX, batteryY - batteryTextHeight * 0.3, Gfx.FONT_XTINY, battery.format("%d") + "%", Gfx.TEXT_JUSTIFY_LEFT);		
		}
	}
		
	function updateViewNameLayer(dc) {
	    dc.setColor(foregroundColor, backgroundColor);
    	dc.clear();
    	var text;
    	switch (status) {
			case Controller.STAT_STD:
				text = WatchUi.loadResource(Rez.Strings.view_title_current);
				break;
			case Controller.STAT_LAP:
				text = WatchUi.loadResource(Rez.Strings.view_title_lap);
				break;
			case Controller.STAT_TOTAL:
				text = WatchUi.loadResource(Rez.Strings.view_title_total);
				break;
			default:
				text = "";
				System.println("The value is not 1 or 2!");
		}
    	dc.drawText(dc.getWidth()/2, 0, Gfx.FONT_XTINY, text, Gfx.TEXT_JUSTIFY_CENTER);
	}
		
	function updateGrid(dc){
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		dc.clear();
		
	    dc.setPenWidth(2);
		
		var lineStartX;
		var lineStartY;
		var lineWidth;
		var lineHeight;
		
		lineStartX = scale(30);
		lineStartY = scale(60);
		lineWidth = scale(180);
		lineHeight = scale(0);
		dc.drawLine(lineStartX, lineStartY, lineWidth + lineStartX, lineStartY + lineHeight);
		
		lineStartX = scale(10);
		lineStartY = scale(120);
		lineWidth = scale(220);
		lineHeight = scale(0);
		dc.drawLine(lineStartX, lineStartY, lineWidth + lineStartX, lineStartY + lineHeight);
		
		lineStartX = scale(30);
		lineStartY = scale(180);
		lineWidth = scale(180);
		lineHeight = scale(0);
		dc.drawLine(lineStartX, lineStartY, lineWidth + lineStartX, lineStartY + lineHeight);
		
		lineStartX = scale(120);
		lineStartY = scale(60);
		lineWidth = scale(0);
		lineHeight = scale(170);
		dc.drawLine(lineStartX, lineStartY, lineWidth + lineStartX, lineStartY + lineHeight);
		
		// Draw average symbol
		if (status == Controller.STAT_LAP || status == Controller.STAT_TOTAL){
        	dc.setColor(Gfx.COLOR_WHITE, backgroundColor);
			dc.fillCircle(scale(120), scale(120), 11);
        	dc.setColor(Gfx.COLOR_WHITE, backgroundColor);
			dc.drawCircle(scale(120), scale(120), 12);
        	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
			//dc.drawText(scale(124), scale(120), Gfx.FONT_TINY, "Ø", Gfx.TEXT_JUSTIFY_VCENTER);
			dc.setPenWidth(2);
			dc.drawEllipse(scale(120), scale(120), 4, 6);
			dc.drawLine(scale(115.5), scale(127), scale(125.5), scale(113));
		}
	}
	
	
	
	// Rolling window
	/*
	var cadenceRollingWindowSize = 60;
	var array = new [cadenceRollingWindowSize];
	for( var i = 0; i < cadenceRollingWindowSize; i += 1 ) {
		array[i] = new [2];
	}
	*/
	

}
