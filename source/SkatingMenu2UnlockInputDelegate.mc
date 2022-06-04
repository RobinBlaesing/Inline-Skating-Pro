using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Application;


class Menu2unlockDelegate extends WatchUi.Menu2InputDelegate {
    
    var unvalidView;
    var qOwnBytes = [
        244, 118, 18, 34, 98, 44, 118, 179, 100, 25, 204, 207, 12, 
        92, 20, 220, 245, 228, 221, 26, 99, 84, 160, 118, 66, 20, 
        109, 253, 101, 98, 239, 233, 66, 23, 124, 210, 65, 163, 160, 
        57, 157, 85, 209, 90, 174, 203, 155, 43, 93, 19, 13, 208, 131, 
        131, 246, 111
    ]b;

    function initialize() {
        System.println("initialize SkatingMenu2unlockDelegate");
        Menu2InputDelegate.initialize();
        unvalidView = new $.UnvalidCodeView();

    }

    function onSelect(item) {

        // get private key from Storage:
        var dWatchBytes = Application.Storage.getValue("dWatch");
        System.println("dWatchBytesfromStorage" + dWatchBytes);

        var keyPairWatch = new Cryptography.KeyPair({
            :algorithm => Cryptography.KEY_PAIR_ELLIPTIC_CURVE_SECP224R1,
            :privateKey => dWatchBytes
        });

        System.println("publickey" + keyPairWatch.getPublicKey().getBytes());
        System.println("privatekey" + keyPairWatch.getPrivateKey().getBytes());
        

        //generate key agreement, add qOwn:
        var keyAgreementWatch = new Cryptography.KeyAgreement({
            :protocol => Cryptography.KEY_AGREEMENT_ECDH,
            :privateKey => keyPairWatch.getPrivateKey()
        });

        var qOwn = Cryptography.createPublicKey(
            Cryptography.KEY_PAIR_ELLIPTIC_CURVE_SECP224R1, qOwnBytes
        );

        keyAgreementWatch.addKey(qOwn);

        //generate secret:
        var secret = keyAgreementWatch.generateSecret().toString();
        System.println("generatedSecret: " + secret);

        //get secret from manual entry and compare:
        var secretOwn = Application.Properties.getValue("Code");
        System.println("secretOwn: " + secretOwn);

        if(secretOwn.equals(secret)) {
            System.println("Secrets Match!");
            Application.Storage.setValue("unlocked", true);
            item.setEnabled(true);
        } else {
            WatchUi.pushView(unvalidView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_IMMEDIATE);
            item.setEnabled(false);
        }

        // item.setEnabled(true);
            
    }
}



class UnvalidCodeView extends WatchUi.View {

    hidden var myText;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        myText = new WatchUi.Text({
            :text=>"unvalid code",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_LARGE,
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER
        });
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        myText.draw(dc);
    }
}