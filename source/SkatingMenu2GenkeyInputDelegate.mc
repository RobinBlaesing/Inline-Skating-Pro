using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Application;


class Menu2genkeyDelegate extends WatchUi.Menu2InputDelegate {


    function initialize() {
        System.println("initialize SkatingMenu2unlockDelegate");
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {

        //create key pair and display public key in settings:
        var keyPairWatch = new Cryptography.KeyPair({
            :algorithm => Cryptography.KEY_PAIR_ELLIPTIC_CURVE_SECP224R1
        });
        
        //Public key to Properties, private key to Storage:
        var dWatchBytes = keyPairWatch.getPrivateKey().getBytes(); 
        System.println("dWatchBytes"+dWatchBytes);
        
        var qWatchBytes = keyPairWatch.getPublicKey().getBytes(); 
        var qWatchStr = qWatchBytes.toString();
        System.println("qWatchStr"+qWatchStr);

        Application.Storage.setValue("dWatch", dWatchBytes); 
        Application.Properties.setValue("qWatch", qWatchStr);

        //set genkey Storage to true:
        Application.Storage.setValue("genkey", true);

        // item.setEnabled(true);
            
    }
}

