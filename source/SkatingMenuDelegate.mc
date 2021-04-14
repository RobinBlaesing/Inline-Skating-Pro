using Toybox.WatchUi;
using Toybox.System;

class SkatingMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        System.println("initialize SkatingMenuDelegate");
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :item_1) {
            System.println("item 1");
        } else if (item == :item_2) {
            System.println("item 2");
        }
    }

}