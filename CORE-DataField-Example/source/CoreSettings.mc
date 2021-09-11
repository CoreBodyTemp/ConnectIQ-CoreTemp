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


class CoreSettings {
	static const KEY_ANT_ID = "ANT_ID";
	static const KEY_HRM_ID = "HRM_ID";
	static const KEY_FIT_COMPATABILITY = "fitFileCompatability";


    static function getCoreProperty(key,defaultValue) {
    	// Get the stored value
    	//---------------------
		var result = defaultValue;
        var app = Application.getApp();

        if ((app != null) && (key != null)) {
	        result = app.getProperty( key );	// get the stored value
	        
	        if(result == null) {
	            result = defaultValue;
	        }        
        }

        return result;
    }   // end func getCoreProperty


    static function setCoreProperty(key,value) {
    	// Set the stored value
    	//---------------------
		var app = Application.getApp();
				
     	if ((app != null) && (key != null)) {
        	app.setProperty( key, value);		// set the stored value
       	}
    }   // end func setCoreProperty
    

	//-----------------
	// get/set ANT id's
	//-----------------
    static function getCoreAntId() {
		return getCoreProperty(KEY_ANT_ID, 0);
    }   // end func getCoreAntId
    
    static function setCoreAntId(value) {
        setCoreProperty(KEY_ANT_ID, value);
    }   // end func setCoreAntId

	static function getPairedHrmId() {
		// If we can read the paired HRM id to the display device send that
		//   otherwise get the HRM id stored in settings - or just ignore request
		return getCoreProperty(KEY_HRM_ID, 0);
	}	// end func getPairedHrmId
    
	static function setPairedHrmId(value) {
		return setCoreProperty(KEY_HRM_ID, value);
	}	// end func setPairedHrmId
    
    static function getFitBackCompatability() {
        return getCoreProperty(KEY_FIT_COMPATABILITY, true);
    }   // end func getFitBackCompatability

    static function setFitBackCompatability(value) {
        setCoreProperty(KEY_FIT_COMPATABILITY, value);
    }   // end func setFitBackCompatability

}   // end class CoreSettings
