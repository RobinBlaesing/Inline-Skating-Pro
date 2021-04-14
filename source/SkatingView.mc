using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System as Sys;

class SkatingView extends Ui.View {

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

	// Layers
	var gridLayer;
	var batteryLayer;
	var clockLayer;
	var iconsConnectedLayer;
	var accuracyLayer;
	var speedLayer;
	var distanceLayer;
	var cadenceLayer;
	var strideLengthLayer;
	var timerLayer;
	
	// TODOs:
	// Heart rate
	// Training effect
	// Calories
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
        setLayout(Rez.Layouts.MainLayout(dc));
        
        dc.clear();
        dc.setColor(foregroundColor, backgroundColor);
        dc.clear();
        
        sw = dc.getWidth() / 100.0;		// Screen width in percent
        sh = dc.getHeight() / 100.0;	// Screen height in percent
        
        // Fit all displayed items to screen dimensions:
		stdFontHeight = Gfx.getFontHeight(stdFont);
        screenSizeScale = 100*sw / stdScreenSize.toFloat();
        rescaleStdFont();
        System.println("Screen width: " + 100*sw + " -> scale factor: " + screenSizeScale.format("%f") + " --> font size: " + stdFont);
        
        // Custom layouts
        // Position is measured for standard screen size
        // Width and height needs to be scaled (height can be stdFontHeight for auto-height)
        
        gridLayer = new Ui.Layer({:locX=>0, :locY=>0, :width=>100*sw-1, :height=>100*sh-1});
        addLayer(gridLayer);
        
        iconsConnectedLayer = new Ui.Layer({:locX=>64*sw, :locY=>8.5*sh, :width=>30, :height=>30});
        addLayer(iconsConnectedLayer);
        
        accuracyLayer = new Ui.Layer({:locX=>21.5*sw, :locY=>7*sh, :width=>30, :height=>15*sh});
        addLayer(accuracyLayer);
        
        clockLayer = new Ui.Layer({:locX=>35*sw, :locY=>1.5*sh, :width=>30*sw, :height=>12.5*sh});
        addLayer(clockLayer);
        
        batteryLayer = new Ui.Layer({:locX=>39.5*sw, :locY=>15*sh, :width=>23*sw, :height=>7*sh});
        addLayer(batteryLayer);
         
        var leftUpper = {:locX=>10, :locY=>62, :width=>scale(105), :height=>scale(57)};
        speedLayer = new Ui.Layer(leftUpper);
        rescaleLayerPos(speedLayer);
        addLayer(speedLayer);
        
        var leftLower = {:locX=>122, :locY=>62, :width=>scale(105), :height=>scale(57)};
        distanceLayer = new Ui.Layer(leftLower);
        rescaleLayerPos(distanceLayer);
        addLayer(distanceLayer);
        
        var rightUpper = {:locX=>10, :locY=>122, :width=>scale(105), :height=>scale(57)};
        cadenceLayer = new Ui.Layer(rightUpper);
        rescaleLayerPos(cadenceLayer);
        addLayer(cadenceLayer);
        
        var rightLower = {:locX=>122, :locY=>122, :width=>scale(105), :height=>scale(57)};
        strideLengthLayer = new Ui.Layer(rightLower);
        rescaleLayerPos(strideLengthLayer);
        addLayer(strideLengthLayer);
        
        var bottom = {:locX=>35*sw, :locY=>86*sh, :width=>30*sw, :height=>12.5*sh};
        timerLayer = new Ui.Layer(bottom);
        addLayer(timerLayer);
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
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
        System.println("onHide SkatingView");
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
        
        // Update general layers
        
        updateGrid(gridLayer.getDc());
        
        updateConnections(iconsConnectedLayer.getDc());
        
        updateBattery(batteryLayer.getDc());
        
        updateClock(clockLayer.getDc());
        
        updateSpeed(speedLayer.getDc());
        
        updateElapsedDistance(distanceLayer.getDc());
        
        updateCadence(cadenceLayer.getDc());
        
        updateStrideLength(strideLengthLayer.getDc());
        
        updatePositionAccuracy(accuracyLayer.getDc());
        
        updateTimer();
    }
    
	
	// Return largest possible font for DC
	function maxFontDc(dc,text,isNumber) {
    	return maxFont(dc,text,isNumber,dc.getWidth(),dc.getHeight());			
	}
	
	function maxFont(dc,text,isNumber,width,height) {
		var font = Gfx.FONT_XTINY;						// Start with smallest font size
		var textStr = (text instanceof Toybox.Lang.String) ? text : text.toString();
		var textDim = dc.getTextDimensions(textStr, font);
    	while (width >= textDim[0] && height >= textDim[1]) {
    		font++;
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
    
    
    // Update layer functions:  
    
    
    function updateConnections(dc) {
    	dc.clear();
    	
    	if (Sys.getDeviceSettings().phoneConnected) {
	    	dc.setColor(foregroundColor, Gfx.COLOR_TRANSPARENT);
	    	dc.drawText(dc.getWidth()-1, 0, iconsConnected, ICON_CONNECTED_PHONE, Gfx.TEXT_JUSTIFY_RIGHT); 
    	}
    }
    
    function updateClock(dc){
    	dc.clear();
    	
    	var clockTime = System.getClockTime();
        var timeStringHour = clockTime.hour.format("%02d");
        var timeStringMin = clockTime.min.format("%02d");
        var timeStr = Lang.format("$1$:$2$", [timeStringHour, timeStringMin]);
        var font = maxFontDc(dc,timeStr,true);
        
        dc.setColor(foregroundColor, Gfx.COLOR_TRANSPARENT);	
	    dc.drawText(dc.getWidth()/2, 0, font, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
    }
		
	function updateGrid(dc){
		dc.clear();
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
		
	    dc.setPenWidth(3);
		
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
		lineHeight = scale(120);
		dc.drawLine(lineStartX, lineStartY, lineWidth + lineStartX, lineStartY + lineHeight);
	}
    
    function updatePosition(info) {
    	updatePositionAccuracy(accuracyLayer.getDc());
    }
    
	function updateSpeed(dc){
		var currentSpeed = Activity.getActivityInfo().currentSpeed;
		var speed = (currentSpeed != null) ? (currentSpeed * 3.6).format("%.1f") : "-";
		var speedUnit = "km/h";
	
		drawValueUnit(dc, speed, speedUnit);
	}
    	
    	function updatePositionAccuracy(dc){
    		var info = Position.getInfo();
    		
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
	        
	        dc.drawLine(dcW*0.2-pen, (dcH-fontHeight)*0.8, dcW*0.2-pen, dcH-1-fontHeight);	
	        if (info.accuracy < 1) { dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor); } 
	        dc.drawLine(dcW*0.4-pen, (dcH-fontHeight)*0.6, dcW*0.4-pen, dcH-1-fontHeight);  
	        if (info.accuracy < 2) { dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor); } 
	        dc.drawLine(dcW*0.6-pen, (dcH-fontHeight)*0.4, dcW*0.6-pen, dcH-1-fontHeight);  
	        if (info.accuracy < 3) { dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor); } 
	        dc.drawLine(dcW*0.8-pen, (dcH-fontHeight)*0.2, dcW*0.8-pen, dcH-1-fontHeight); 
	        if (info.accuracy < 4) { dc.setColor(Gfx.COLOR_DK_GRAY, backgroundColor); }
	        dc.drawLine(dcW-pen, 1, dcW-pen, dcH-1-fontHeight);
    	}
    
    function updateElapsedDistance(dc){    
        var distance = "-";
        var distanceUnit = "m";
        var elapsedDistance = Activity.getActivityInfo().elapsedDistance;
        System.println("Elapsed distance: " + elapsedDistance);
        if (elapsedDistance != null){
        	if (elapsedDistance < 1000){
        		distance = elapsedDistance.format("%i");
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
		
		drawValueUnit(dc, distance, distanceUnit);	
    }
    
    function updateCadence(dc){ 
        var cadence = "-";
        var cadenceUnit = "spm";
        
        if (cadenceLast != 0.0){
			cadence = cadenceLast.toNumber().format("%i");
		}
        
        drawValueUnit(dc, cadence, cadenceUnit);
    }
    
    function updateStrideLength(dc){
        var strideLength = "-";
        var strideLengthUnit = "m";
        
        	System.println(strideLengthLast);
        if (strideLengthLast != 0.0 && strideLengthLast != null){
        	System.println("Stride length: " + strideLengthLast.format("%f"));
			strideLength = strideLengthLast.format("%.1f");
		}
        
        drawValueUnit(dc, strideLength, strideLengthUnit);
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
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);	
	    	dc.drawText(6, 0, customIcons, ICON_BATTERY, Gfx.TEXT_JUSTIFY_LEFT); 
	        dc.drawText(batteryX, batteryY - batteryTextHeight * 0.3, Gfx.FONT_XTINY, battery.format("%d") + "%", Gfx.TEXT_JUSTIFY_LEFT);		
		}
		
	}
	
	
	function updateTimer() {
		var dc = timerLayer.getDc();
		var dcW = dc.getWidth();
        var dcH = dc.getHeight();
		
		var activityTimeSec = Activity.getActivityInfo().elapsedTime/1000;
		var hr = activityTimeSec/3600;  
		
		if (hr > 0) {
			dc.setColor(foregroundColor, backgroundColor);
			dc.clear();
			var hourWidth = dcW/6.0;
			var hourHeight = dcH/2.0;
			var spacer = dcW/10.0;
			var hrStr = hr.toString();
        	var fontH = maxFont(dc, hrStr, true, hourWidth, hourHeight);
	        var fontHWidth = dc.getTextDimensions(hrStr, fontH)[0];
	        dc.drawText(fontHWidth/2, centerFontVert(hourHeight,fontH),fontH, hrStr, Gfx.TEXT_JUSTIFY_CENTER);	
	        
			var msStr = toMS(activityTimeSec).toString();
			var msWidth = dcW-hourWidth-spacer;
        	var fontMS = maxFont(dc, msStr, true, msWidth, dcH);
	        var fontMSWidth = dc.getTextDimensions(msStr, fontH)[0];
	        dc.drawText(fontMSWidth/2+spacer+hourWidth, centerFontVert(dcH,fontMS),fontMS, msStr, Gfx.TEXT_JUSTIFY_CENTER);	
        }
        else {
        	drawValueUnit(dc,toMS(activityTimeSec).toString(),null);
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
	
	// Rolling window
	/*
	var cadenceRollingWindowSize = 60;
	var array = new [cadenceRollingWindowSize];
	for( var i = 0; i < cadenceRollingWindowSize; i += 1 ) {
		array[i] = new [2];
	}
	*/
	

}
