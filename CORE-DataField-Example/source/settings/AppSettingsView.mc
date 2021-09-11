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

using Toybox.WatchUi;


class AppSettingsDelegate extends WatchUi.Menu2InputDelegate {
	hidden var mMenu;
	hidden var mCoreField;
	
	
	function initialize(coreField) {
		mCoreField = coreField;
		Menu2InputDelegate.initialize();
    }	// end func initialize

    
	function onSelect(item) {
		if( item.getId().equals(CoreSettings.KEY_ANT_ID.toString()) ) {
			var deviceCORENumberPicker = new DeviceNumberPicker(CoreSettings.KEY_ANT_ID.toString());
			WatchUi.pushView(deviceCORENumberPicker, new DeviceNumberPickerDelegate(deviceCORENumberPicker), WatchUi.SLIDE_IMMEDIATE );
		} else if( item.getId().equals(CoreSettings.KEY_HRM_ID.toString()) ) {
			var deviceHRMNumberPicker = new DeviceNumberPicker(CoreSettings.KEY_HRM_ID.toString());
			WatchUi.pushView(deviceHRMNumberPicker, new DeviceNumberPickerDelegate(deviceHRMNumberPicker), WatchUi.SLIDE_IMMEDIATE );
		} else if( item.getId().equals(CoreSettings.KEY_FIT_COMPATABILITY.toString()) ) {
			CoreSettings.setFitBackCompatability(item.isEnabled());
		}			
	}	// end func onSelect

	
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);

    	if ( mCoreField != null ) {				// trigger a settings refresh
	    	mCoreField.dataFieldReset( false );
	    }
    }	// end func onBack
}	// end class AppSettingsDelegate


class AppSettingsView extends WatchUi.Menu2 {
	hidden var mHrmIdNumber;
	hidden var mDeviceNumber;
	
	function initialize() {
		Menu2.initialize({:title=>"Settings"});
		
		mDeviceNumber = CoreSettings.getCoreAntId();
		addItem(
			new WatchUi.MenuItem(
				Rez.Strings.ANT_ID_title,
				mDeviceNumber.toString(),
				CoreSettings.KEY_ANT_ID.toString(),
				{}
				)
			);

		addItem(
			new WatchUi.ToggleMenuItem(
				Rez.Strings.fitFileCompatability_title,
				null,
				CoreSettings.KEY_FIT_COMPATABILITY.toString(),
				CoreSettings.getFitBackCompatability(),
				{}
			)
		);

		mHrmIdNumber = CoreSettings.getPairedHrmId();
		addItem(
			new WatchUi.MenuItem(
				Rez.Strings.HRM_ID_title,
				mHrmIdNumber.toString(),
				CoreSettings.KEY_HRM_ID.toString(),
				{}
				)
			);
	}	// end func initialize
	
	function onShow() {
		var item;
		var hrmIdNumber = CoreSettings.getPairedHrmId();
		var deviceNumber = CoreSettings.getCoreAntId();
		
		if((deviceNumber != mDeviceNumber) && (deviceNumber <= 65535)) {	// 0xFFFF
			mDeviceNumber = deviceNumber;
			item = self.getItem(0);

			if(item != null) {
				item.setSubLabel(mDeviceNumber.toString());
				self.updateItem(item, 0);
			}
			CoreSettings.setCoreAntId(deviceNumber);
		}

		if((hrmIdNumber != mHrmIdNumber) && (hrmIdNumber <= 1048575)) {		// 0xFFFFF
			mHrmIdNumber = hrmIdNumber;
			item = self.getItem(2);

			if(item != null) {
				item.setSubLabel(mHrmIdNumber.toString());
				self.updateItem(item, 2);
			}
			CoreSettings.setPairedHrmId(mHrmIdNumber);
		}
	}	// end func onShow
}	// end class AppSettingsView