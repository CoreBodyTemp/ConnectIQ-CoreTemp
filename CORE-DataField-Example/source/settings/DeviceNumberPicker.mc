/* Copyright (C) 2021, greenTEG AG
 *    info@CoreBodyTemp.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

using Toybox.Application;
using Toybox.Graphics;
using Toybox.WatchUi;


class DeviceNumberPicker extends WatchUi.Picker {
    const mCharacterSet = "0123456789";
    hidden var mTitleText;
    hidden var mFactory;
    var mDeviceKey;

    function initialize(deviceKey) {
    	mDeviceKey = deviceKey;
        mFactory = new CharacterFactory(mCharacterSet, {:addDone=>true, :addDelete=>true});
        mTitleText = "";

        var string = Application.getApp().getProperty(mDeviceKey).toString();
        var defaults = null;
        var titleText = loadTitle();

        if(string != null) {
            mTitleText = string;
            titleText = string;
            defaults = [mFactory.getIndex(string.substring(string.length()-1, string.length()))];
        }

        mTitle = new WatchUi.Text({:text=>titleText, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});

        Picker.initialize({:title=>mTitle, :pattern=>[mFactory], :defaults=>defaults});
    }	// end func initalize


    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }	// end func onUpdate


    function addCharacter(character) {
        mTitleText += character;
        mTitle.setText(mTitleText);
    }	// end func addCharacter


    function removeCharacter() {
        mTitleText = mTitleText.substring(0, mTitleText.length() - 1);

        if(0 == mTitleText.length()) {
            mTitle.setText( WatchUi.loadResource( loadTitle()));
        }
        else {
            mTitle.setText(mTitleText);
        }
    }	// end func removeCharacter


	function loadTitle() {
        if ( mDeviceKey.equals(CoreSettings.KEY_HRM_ID.toString()) ) {
        	return Rez.Strings.HRM_ID_title;
        }
       	return Rez.Strings.ANT_ID_title;
	}	// end func loadTitle
	

    function getTitle() {
        return mTitleText.toString();
    }	// end func getTitle


    function getTitleLength() {
        return mTitleText.length();
    }	// end func getTitleLength


    function isDone(value) {
        return mFactory.isDone(value);
    }	// end func isDone

    
    function isDelete(value) {
        return mFactory.isDelete(value);
    }	// end func isDelete
}	// end class DeviceNumberPicker


class DeviceNumberPickerDelegate extends WatchUi.PickerDelegate {
    hidden var mPicker;

    function initialize(picker) {
        PickerDelegate.initialize();
        mPicker = picker;
    }	// end func initialize

    function onCancel() {
        if(0 == mPicker.getTitleLength()) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        else {
            mPicker.removeCharacter();
        }
    }	// end func onCancel

    function onAccept(values) {
        if(mPicker.isDelete(values[0])) {
        	mPicker.removeCharacter();
        }
        else if(mPicker.isDone(values[0])) {
        	if(mPicker.getTitle().length() == 0) {
                Application.getApp().setProperty(mPicker.mDeviceKey, 0);
            }
            else {
                Application.getApp().setProperty(mPicker.mDeviceKey, mPicker.getTitle().toNumber());
            }
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        else {
        	mPicker.addCharacter(values[0]);
        }
    }	// end func onAccept
}	// end class DeviceNumberPickerDelegate