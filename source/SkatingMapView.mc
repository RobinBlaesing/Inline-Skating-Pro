//
// Copyright 2018-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Graphics;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;

//! This view shows a map with the current device location
class SkatingMapView extends WatchUi.MapTrackView {

    //! Constructor
    public function initialize() {
        MapTrackView.initialize();

        // set the current mode for the map to preview
        setMapMode(WatchUi.MAP_MODE_PREVIEW);

        // create the bounding box for the map area
        var posInfo = Position.getInfo();
        var pos = posInfo.position.toDegrees();
        var speed = Activity.getActivityInfo().currentSpeed;
        var viewDis = (speed > 2.5) ? 300 : 100; 
        var top_left = new Position.Location({:latitude => pos[0]+viewDis, :longitude =>pos[1]+viewDis, :format => :degrees});
        var bottom_right = new Position.Location({:latitude => pos[0]-viewDis, :longitude =>pos[1]-viewDis, :format => :degrees});
        MapView.setMapVisibleArea(top_left, bottom_right);

        // set the bound box for the screen area to focus the map on
        MapView.setScreenVisibleArea(0, System.getDeviceSettings().screenHeight / 2, System.getDeviceSettings().screenWidth, System.getDeviceSettings().screenHeight);
    }

    //! Load your resources here
    //! @param dc Device context
    public function onLayout(dc) {
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    public function onShow() {
    }

    //! Update the view
    //! @param dc Device context
    public function onUpdate(dc) {
    
    	var posInfo = Position.getInfo();
        var pos = posInfo.position.toDegrees();
        var speed = Activity.getActivityInfo().currentSpeed;
        var viewDis = (speed > 2.5) ? 400 : 200; 
        var top_left = new Position.Location({:latitude => pos[0]+viewDis, :longitude =>pos[1]+viewDis, :format => :degrees});
        var bottom_right = new Position.Location({:latitude => pos[0]-viewDis, :longitude =>pos[1]-viewDis, :format => :degrees});
        MapView.setMapVisibleArea(top_left, bottom_right);
    
        // call the parent onUpdate function to redraw the layout
        MapView.onUpdate(dc);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    }
}
