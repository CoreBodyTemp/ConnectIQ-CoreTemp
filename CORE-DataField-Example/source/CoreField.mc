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

using Toybox.System;
using Toybox.WatchUi;
using Toybox.Attention;
using Toybox.Application;


// --------------------------------------
//  Main() Entry Point - Simple DataField
// --------------------------------------
class CoreDataField extends Application.AppBase {
    static var mSensor;
    static var mCoreField;


	//----------------------------------------------
	// Core Data Field - main() / UI components
	//----------------------------------------------
	class CoreField extends WatchUi.SimpleDataField { 
		static const DISP_NULL = 0;
		static const DISP_FORMAT = 0;
		static const DISP_APPEND = 1;
		static const CELCIUS_INDEX = 0;
		static const FAHRENHEIT_INDEX = 1;
	    static const DISP_SKIN_OPT = 1;		// alternate skin temp and core temp
		static const DISP_RESV_OPT = 4;		// alternate core, skin & HF
			
	    var mFitContributor;				// Fit Contributor
	    var unitsIndex = CELCIUS_INDEX;		// Celsius by default
	    
		var displayCount;
		var fitCompatability;
		var lastValidCoreTemp;
		var searchingFrozenCount;
		var lastTempChangeDispCount;
		var showOptionalDisplay;


		//-------------------------------------
		// Initialize/load resources
	    // Set the label of the data field here
		//-------------------------------------
	    function initialize(sensor) {
	    	mSensor = null;
	    	mFitContributor = null; 
	
			var dataFieldLabel = initFieldData();
	
			// get it all started...
	        mSensor = sensor;
	        mFitContributor = new CoreFitContributor(self, fitCompatability);
	
	        SimpleDataField.initialize();
	        label = dataFieldLabel;
	    }	// end func initialize
	
	
		//----------------------------------------------------------------------
		// compute the field - display temperature CORE data
	    // The given info object contains all the current workout
	    // information. Calculate a value and return it in this method.
	    // Note that compute() and onUpdate() are asynchronous, and there is no
	    // guarantee that compute() will be called before onUpdate().
		//----------------------------------------------------------------------
	    function compute(info) {
		    var CalcTemp;
		    // Data Quality: 0= --.--C, 1= #-.--C, 2= ##.--C, 3= ##.#-C, 4= ##.##C
		    // Data Quality: 0= ---.-F, 1= ##-.-F, 2= ###.-F, 3= ###.#F, 4= ###.#F
			var dataQualFormat = [ [[ "", "%1d", "%02d", "%.2f", "%.2f" ], [ "--.--", "-.--", ".--", "",  "" ] ], 
		  		 			       [[ "", "%2d", "%02d", "%.1f", "%.1f" ], [ "---.-", "-.-" , ".-" , "" , "" ] ] ];
	
			if ((mSensor == null) || ((mSensor.msgTimeStamp != null) && ((Time.now().value() - mSensor.msgTimeStamp.value()) > (mSensor.SENSOR_TIMEOUT + 5)))) {
				// if no sensor or it is 'stuck' after a sleep mode, no input from ant sensor after
				dataFieldReset( true );											// sensor hard reset!!
				return WatchUi.loadResource(Rez.Strings.msgLostSignal);			// "Lost Signal"		
			}
			
			CalcTemp = getTemperatureValue();
	       	displayCount++;		// approximatly one tick per second
	       	
	        if ( mSensor.searching > 0 ) {
				//----------------------------------------------
				// searching for CORE ANT+ sensor
				//		display old valid temp for 29 seconds
				//		display --.-- blank for first 5 seconds
				//		display Searching... 5 to 7 seconds
				//		display shake core or antid 7 to 9 sec
				//----------------------------------------------
	        	mSensor.searching++;	// approximatly ticks / seconds searching
	        	
	        	if ((mSensor.searching <= 29) && mSensor.data.isValidCoreTemp( lastValidCoreTemp )) {
	        		// display the last valid temp - make it look like still connected
	        		// fall through to stand display function
					mSensor.data.CoreTemp = lastValidCoreTemp;
	        	} else { 
	        		lastValidCoreTemp = 0;
		        	displayCount = 0;
		        	lastTempChangeDispCount = 0;
		        	
					searchingFrozenCount++;
					if ( searchingFrozenCount > 73 ) {		// nothing found for about 103 seconds
						// searching looks frozen - reset the sensor
						dataFieldReset( false );
						return WatchUi.loadResource(Rez.Strings.msgSearching);			// "Searching..."
					}

	        		if ( mSensor.searching % 8 < 4 ) {
						// first time displaying show --.-- (C) or ---.- (F) for the first 4 seconds
						return  dataQualFormat[unitsIndex][DISP_APPEND][DISP_NULL];		//StringUtil.([0xC2,0xB0]) "°"
	        		} else if ( mSensor.searching % 8 < 6 ) {
						return WatchUi.loadResource(Rez.Strings.msgSearching);			// "Searching..."
			        } else {
			        	if ( mSensor.ANTid > 0 ) {
			           		return  mSensor.ANTid.format("%05u");						// ANT id search for
			        	} else {									
							return WatchUi.loadResource(Rez.Strings.msgShakeCore);		// wildcard search - "Shake CORE"
			           	}
			        }
		        }
			} else {
				searchingFrozenCount = 0;
			}	

			if ( mSensor.data.isValidCoreTemp( mSensor.data.CoreTemp ) == false ) {
				//----------------------------------------------
				// Invalid CORE temperature - calculating
				//		display --.-- blank for 5 of 7 seconds
				//		display Calculating for 2 of 7 sec
				//----------------------------------------------
				if ( displayCount % 7 < 5 ) {		// display --.--C or ---.-F
					return  dataQualFormat[unitsIndex][DISP_APPEND][DISP_NULL];
				} else {
					return WatchUi.loadResource(Rez.Strings.msgCalculating );			// display "Calculating..."			
				}
			} 
			
			//-----------------------
			// Valid CORE temperature
			//-----------------------
			if ( datafieldFrozen(mSensor.data.CoreTemp)) {
				// if the Sensor seems to be 'stuck' - re-initialize the datafield
				dataFieldReset( false );												// force a 'reset'
			}
			lastValidCoreTemp = mSensor.data.CoreTemp;
	
			// could check and display alert - ask if you would like source code
				
			if ((mSensor.data.batteryState == mSensor.data.BATTERY_CRITICAL) && (displayCount % 8 < 2)) {
				return WatchUi.loadResource(Rez.Strings.msgLowBattery);					// "Low Battery" - display Low Battery warming		
			} else if ( mSensor.data.batteryState == mSensor.data.BATTERY_NOT_SET ) {
            	if ( displayCount % 3 < 2 ) {
	            	mSensor.requestPage( mSensor.PAGE_BATTERY );			  		    // request battery page
            	} else {
    	        	mSensor.requestPage( mSensor.PAGE_CORE_INFO );				  		// request device info page
            	}
			}
				
		    //--------------------------------------------------------------------
			// Display/Format CORE Temperature (C or F)
			//		indicate poor quality data with follow guidelines
		    // Data Quality: 0= --.--C, 1= ##.--C, 2= ##.#-C, 3= ##.##C, 4= ##.##C
		    // Data Quality: 0= ---.-F, 1= ##-.-F, 2= ###.-F, 3= ###.#F, 4= ###.#F
		    //--------------------------------------------------------------------
	       	var dispCoreField = null;
			var dataQuality = mSensor.data.dataQuality;
	
			if ((dataQuality < 4) && displayCount % 6 >= 1) {
				dataQuality = 4;		// force a flash of the core temp and bad quality
			}
	
	        switch ( dataQuality ) {
	        	case 1: {	// remove the last digit before the decimal - inidcating poor quality data
	        		dispCoreField = (CalcTemp / 10).format(dataQualFormat[unitsIndex][DISP_FORMAT][dataQuality]) + dataQualFormat[unitsIndex][DISP_APPEND][dataQuality];
	        		break;
	        	}
	        	case 2: 
	        	case 3:	
	        	case 4:	 {
	        		dispCoreField = CalcTemp.format(dataQualFormat[unitsIndex][DISP_FORMAT][dataQuality]) + dataQualFormat[unitsIndex][DISP_APPEND][dataQuality];
	        		break;
	        	}
	        	case 0:  	// poor quality data - do not show any value
	        	default: {
	        		dispCoreField = dataQualFormat[unitsIndex][DISP_FORMAT][DISP_NULL];
	        		break;
	        	}
	        }
				 
			//-------------------------------
			// log CORE value in the FIT file 
			//-------------------------------
			if ( mFitContributor != null ) {
		       	mFitContributor.compute(mSensor);
		    }
		    
	        return dispCoreField;		// return the string value to display!
	    }	// end func compute
	
	    
	    function getTemperatureValue() {
	    	var tempValue;
	
	        if (System.getDeviceSettings().temperatureUnits == System.UNIT_METRIC) { 
	            unitsIndex = CELCIUS_INDEX;			// global variable            
	            tempValue = mSensor.data.CoreTemp;   
	        } else {
		        unitsIndex = FAHRENHEIT_INDEX;		// global variable
		        tempValue = ((mSensor.data.CoreTemp * 9.0) / 5.0) + 32.0;        // convert C to F for display
	        }
	        
	        return tempValue;                  
	    }	// end func getTemperatureValue
	
	    
		function initFieldData() {
			// initalize on start and settings changes
			//----------------------------------------
			var dataFieldLabel;
			
			displayCount = 0;
		 	fitCompatability = true;
		 	lastValidCoreTemp = 0.0;
		 	searchingFrozenCount = 0;
		 	lastTempChangeDispCount = 0;
		 	showOptionalDisplay = 0;

			fitCompatability = CoreSettings.getFitBackCompatability();

			if (System.getDeviceSettings().temperatureUnits == System.UNIT_METRIC) { 
				dataFieldLabel = WatchUi.loadResource(Rez.Strings.AppName) + " °C";		// Celsius data field title
			} else {
				dataFieldLabel = WatchUi.loadResource(Rez.Strings.AppName) + " °F";		// Fahrenheit data field title
			}		
	
			return dataFieldLabel;
		}   // end func initFieldData
	
	
		function dataFieldReset( hardReset ) {
			// re-initialize the datafield and sensor
			// on settings change or if field seems to be 'stuck'
			//---------------------------------------------------
			if ( mSensor != null ) {
				mSensor.close();
				
				if ( hardReset == true ) {
					mSensor.release();			// release the ant channel before reopening a new one
					mSensor = null;				// close the sensor and force a re-initialize
				}
			}

			if ( mSensor == null ) {
		        try {
		            //Create the sensor object and open it
		            mSensor = new CoreSensor();
				} catch (e) {
					System.println(e.getErrorMessage());
					System.println(e.printStackTrace());
		            mSensor = null;
				}	        
			}
			
			if ( mSensor != null ) {
				initFieldData();
				mSensor.initialize();		// force the new ANT ID
				mSensor.open();
				mFitContributor.initialize(mCoreField, fitCompatability);
			}
		}	// end func dataFieldReset

					
		function datafieldFrozen(currCoreTemp) {
			// if the values are not changing for some reason - reset the ANT connection
			//--------------------------------------------------------------------------
			if ( lastValidCoreTemp == currCoreTemp ) {
				if ((lastTempChangeDispCount + 270) < displayCount ) {		// over 4.5 minutes = 270 seconds
					return true;
				}
			} else {
				lastTempChangeDispCount = displayCount;
			}
			
			return false;
		}	// end func datafieldFrozen
	
	
		//------------------------------
		// FIT file recording start/stop
		//------------------------------
	    function onNextMultisportLeg() {
	        onTimerReset();
	    }	// end func onNextMultisportLeg
    
	    function onTimerStart() {
	        mFitContributor.setTimerRunning( true, mSensor );
	    }	// end func onTimerStart
	
	    function onTimerStop() {
	        mFitContributor.setTimerRunning( false, mSensor );
	    }	// end func onTimerStop
	
	    function onTimerPause() {
	        mFitContributor.setTimerRunning( false, mSensor );
	    }	// end func onTimerPause
	
	    function onTimerResume() {
	        mFitContributor.setTimerRunning( true, mSensor );
	    }	// end func onTimerResume
	
	    function onTimerLap() {
	        mFitContributor.onTimerLap();
	    }	// end func onTimerLab
	
	    function onTimerReset() {
	        mFitContributor.onTimerReset();
	        mFitContributor.onTimerLap();
	    }	// end func onTimerReset
	
	}  // end class CoreField


	// ---------------------------------------
	//  Main() Class Methods for CoreDataField 
	// ---------------------------------------
    function initialize() {
    	mSensor = null;
    	mCoreField = null;
    	
        AppBase.initialize();
    }	// end func initialize

    // onStart is the primary start point for a Monkeybrains application
    //------------------------------------------------------------------
    function onStart(state) {
        try {
            //Create the sensor object and open it
            mSensor = new CoreSensor();
            mSensor.open();
		} catch (e) {
			System.println(e.getErrorMessage());
			System.println(e.printStackTrace());
            mSensor = null;
		}	        
        
    }	// end func onStart

    function getInitialView() {
        mCoreField = new CoreField(mSensor);
        return [mCoreField];
    }	// end func getInitialView

    function onStop(state) {
    	if ( mSensor != null ) { 
    		mSensor.closeSensor();
    	}
    	
        return false;
    }	// end func onStop
    
    function onSettingsChanged() { 	
    	// triggered by settings change in Phone App settings
    	//---------------------------------------------------
    	if ( mCoreField != null ) {
	    	mCoreField.dataFieldReset( false );
	    }
	}	// end func onSettingsChanged

	function getSettingsView() {
		if ( Toybox.WatchUi has :Menu2 ) {		// menus not supported on old watches
			// on screen menus	
			return [ new AppSettingsView(), new AppSettingsDelegate(mCoreField) ];
		}
	}	// end func getSettingsView
	    
}  // end class CoreDataField
