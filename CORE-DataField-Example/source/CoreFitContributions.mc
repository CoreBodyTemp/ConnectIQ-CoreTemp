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
 
using Toybox.FitContributor;


//----------------------------------------------
// Record CORE temperature data in the FIT file
//----------------------------------------------
class CoreFitContributor {
	
    // FIT Contributions variables
	hidden var mCoreTemp = null;
	hidden var mSkinTemp = null;
	hidden var mCoreQual = null;
	hidden var mCoreResv = null;
	hidden var mConnectIQinfoField = null;
	// write CoreTemp as Moxy fields for backward compatability
	hidden var mSMO2 = null;			
	hidden var mTHB = null;
	
    // Variables for computing averages
    hidden var mLastEvenCount = 0;
    hidden var mTimerRunning = false;


    //----------------------------
    // FIT file contribution class
    //----------------------------
    class coreFitFieldFull {
    	var	currValue = 0;
    	var	currField = null;

    	var	lapAvgValue = 0;
    	var lapAvgField = null;
    	var	lapMaxValue = 0;
    	var lapMaxField = null;
    	var lapMinValue = 0;
    	var lapMinField = null;
		var lapRecordCount = 0;
		
    	var	sessionAvgValue = 0;
    	var	sessionAvgField = null;
    	var	sessionMaxValue = 0;
    	var	sessionMaxField = null;
    	var sessionMinValue = 0;
    	var sessionMinField = null;
    	var sessionRecordCount = 0;
    	
    	var graphField = null;


    	function writeValue( fitValue, TimerRunning, allowZeroValue ) {
    		//----------------------------------------------------------------------
    		// return true if should write the value to FIT file - valid and updated
    		//----------------------------------------------------------------------
    		if ((fitValue == 0) && (allowZeroValue == false)) {
    			return false;			// never mind, ignore...
    		}
    		
            if( TimerRunning == true ) {
            	// Update lap data and record counts
            	lapRecordCount++;
            	lapAvgValue += fitValue;
            	if ((lapMinValue == 0) || (fitValue < lapMinValue )) { 
					lapMinValue = fitValue;
				}
            	if ( fitValue > lapMaxValue ) { 
					lapMaxValue = fitValue;
				}

            	// Update session data and record counts
            	sessionRecordCount++;
            	sessionAvgValue += fitValue;
            	if ((sessionMinValue == 0) || (fitValue < sessionMinValue )) { 
					sessionMinValue = fitValue;
				}
            	if ( fitValue > sessionMaxValue ) { 
					sessionMaxValue = fitValue;
				}
	    	}

   			return true;				// record the value
    	}	//	end func writeValue
    	
    	
    	function resetLapValue( ) {
	        lapAvgValue = 0.0;
	        lapMinValue = 0.0;
	        lapMaxValue = 0.0;
	        lapRecordCount = 0.0;
    	}	// end func resetLapValue
    	

    	function resetSessionValue( ) {
	        sessionAvgValue = 0.0;
	        sessionMinValue = 0.0;
	        sessionMaxValue = 0.0;
	        sessionRecordCount = 0.0;
    	}	// end func resetValue


		function writeLapSessionValues( ) {
	    	// Updatea session FIT Contributions
	        if ( lapRecordCount > 0 ) {
	        	lapAvgField.setData( lapAvgValue.toFloat() / lapRecordCount.toFloat() );
	        	lapMaxField.setData( lapMaxValue.toFloat() );
	        	lapMinField.setData( lapMinValue.toFloat() );
	        }
	        
	        // Updatea session FIT Contributions
	        if ( sessionRecordCount > 0 ) {
	        	sessionAvgField.setData( sessionAvgValue.toFloat() / sessionRecordCount.toFloat() );
	        	sessionMaxField.setData( sessionMaxValue.toFloat() );
	        	sessionMinField.setData( sessionMinValue.toFloat() );
	        }
		}	// end func writeLapSessionValues
		    	
    }	// end class coreFitFieldFull


    class coreFitFieldSimple {
    	var	currValue = 0;
    	var	currField = null;
    	var graphField = null;


    	function writeValue( fitValue, TimerRunning, allowZeroValue ) {
    		// return true if should write the value to FIT file - valid and updated
    		//----------------------------------------------------------------------
			if (((fitValue == 0) && (allowZeroValue == false)) || (TimerRunning == false)) {
	    		return false;			// zero or no change, don't write the value
	    	}

   			return true;				// valued has updated so record it
    	}	//	end func writeValue
    	
    }	// end class coreFitFieldSimple


    function initialize(dataField, fitCompatability) {
		//   FIT_HEADING_CORETEMP = fit_core_temp_label in resource.xml
		var FIT_HEADING_CIQ_INFO 	 = "CIQ_device_info";
		var FIT_HEADING_CORETEMP 	 = "core_temperature";
		var FIT_HEADING_AVG_CORETEMP = "avg_core_temperature";
		var FIT_HEADING_MAX_CORETEMP = "max_core_temperature";
		var FIT_HEADING_MIN_CORETEMP = "min_core_temperature";
		var FIT_C_TEMP_UNITS 		 = "°C";
		var FIT_HEADING_COREQUAL 	 = "core_data_quality";
		var FIT_COREQUAL_UNITS 		 = "Q";
		var FIT_HEADING_SKINTEMP  	 = "skin_temperature";
		var FIT_HEADING_RESERVED 	 = "core_reserved";
		var FIT_RESERVED_UNITS 		 = "kcal";
		var FIT_HEADING_SMO2_CONC 	 = "total_hemoglobin_conc";
		var FIT_SMO2_CONC_UNITS 	 = "g/dl";
		var FIT_HEADING_SMO2_PERC 	 = "saturated_hemoglobin_percent";
		var FIT_SMO2_PERC_UNITS 	 = "%";
		var FIT_HEADING_CORE_GRAPH 	 = "CIQ_core_temperature";
		var FIT_HEADING_SKIN_GRAPH 	 = "CIQ_skin_temperature";
		var FIT_GRAPHTEMP_UNITS 	 = "°";

		var CURR_CORE_TEMP_FIELD_ID  	= 0;
		var LAP_AVG_CORE_TEMP_FIELD_ID 	= 1;
		var LAP_MAX_CORE_TEMP_FIELD_ID 	= 2;
		var LAP_MIN_CORE_TEMP_FIELD_ID 	= 3;
		var AVG_CORE_TEMP_FIELD_ID  	= 5;
		var MAX_CORE_TEMP_FIELD_ID  	= 6;
		var MIN_CORE_TEMP_FIELD_ID  	= 7;
		var CURR_SKIN_TEMP_FIELD_ID 	= 10;
		var CURR_COREQUAL_FIELD_ID  	= 19;
		var CURR_RESERVED_FIELD_ID  	= 20;
		var FIT_CONNECTIQ_INFO_ID	  	= 26;
		// write CoreTemp as Moxy fields for backward compatability
		var CURR_HEMO_CONC_FIELD_ID    	= 30;
		var CURR_HEMO_PERCENT_FIELD_ID 	= 31;

	    //--------------------
	    // Initialize FIT File
	    //--------------------
		if ( dataField != null ) {
			// CORE Temp fields
			if ( mCoreTemp == null ) {
				mCoreTemp = new coreFitFieldFull();
				if ( mCoreTemp != null ) {
					mCoreTemp.currField = dataField.createField(FIT_HEADING_CORETEMP, CURR_CORE_TEMP_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>139, :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>FIT_C_TEMP_UNITS });
		
		        	mCoreTemp.lapAvgField = dataField.createField(FIT_HEADING_AVG_CORETEMP, LAP_AVG_CORE_TEMP_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>158, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>FIT_C_TEMP_UNITS });
		        	mCoreTemp.lapMinField = dataField.createField(FIT_HEADING_MIN_CORETEMP, LAP_MIN_CORE_TEMP_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>159, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>FIT_C_TEMP_UNITS });
		        	mCoreTemp.lapMaxField = dataField.createField(FIT_HEADING_MAX_CORETEMP, LAP_MAX_CORE_TEMP_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>160, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>FIT_C_TEMP_UNITS });
		
		        	mCoreTemp.sessionAvgField = dataField.createField(FIT_HEADING_AVG_CORETEMP, AVG_CORE_TEMP_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>208, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>FIT_C_TEMP_UNITS });
		        	mCoreTemp.sessionMinField = dataField.createField(FIT_HEADING_MIN_CORETEMP, MIN_CORE_TEMP_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>209, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>FIT_C_TEMP_UNITS });
		        	mCoreTemp.sessionMaxField = dataField.createField(FIT_HEADING_MAX_CORETEMP, MAX_CORE_TEMP_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :nativeNum=>210, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>FIT_C_TEMP_UNITS });
	
		        	mConnectIQinfoField = dataField.createField(FIT_HEADING_CIQ_INFO, FIT_CONNECTIQ_INFO_ID, FitContributor.DATA_TYPE_UINT8, { :count=>14, :mesgType=>FitContributor.MESG_TYPE_SESSION });
				}
			}

			if ( mSkinTemp == null ) {
				// Skin Temp fields
				mSkinTemp = new coreFitFieldSimple();
				if ( mSkinTemp != null ) {
		        	mSkinTemp.currField  = dataField.createField(FIT_HEADING_SKINTEMP,   CURR_SKIN_TEMP_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>FIT_C_TEMP_UNITS });
	    		}
			}

			if ( mCoreQual == null ) {
				// Data Quality fields
				mCoreQual = new coreFitFieldSimple();
				if ( mCoreQual != null ) {
				    mCoreQual.currField = dataField.createField(FIT_HEADING_COREQUAL, CURR_COREQUAL_FIELD_ID, FitContributor.DATA_TYPE_SINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>FIT_COREQUAL_UNITS });
				}
			}

			if ( mCoreResv == null ) {
				// Reserved fields
				mCoreResv = new coreFitFieldSimple();
				if ( mCoreResv != null ) {
		        	mCoreResv.currField = dataField.createField(FIT_HEADING_RESERVED, CURR_RESERVED_FIELD_ID, FitContributor.DATA_TYPE_SINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>FIT_RESERVED_UNITS });
				}
			}
					
			if ( fitCompatability && (mTHB == null)) {
        		// write the MOXY backward compatable fields
        		mTHB = new coreFitFieldSimple();
        		mSMO2 = new coreFitFieldSimple();
        		if ((mTHB != null) && (mSMO2 != null)) {
					mTHB.currField = dataField.createField(FIT_HEADING_SMO2_CONC, CURR_HEMO_CONC_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>54, :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>FIT_SMO2_CONC_UNITS });
					mSMO2.currField = dataField.createField(FIT_HEADING_SMO2_PERC, CURR_HEMO_PERCENT_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>57, :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>FIT_SMO2_PERC_UNITS });
				}
        	}       
    	}
	}	// end func initialize

    
    function compute( sensor ) {
        if( sensor != null ) {
        	if (mLastEvenCount != sensor.data.eventCount ) {
        		mLastEvenCount = sensor.data.eventCount;
	        	//-------------------------------------------
    	    	// Write the CoreSensor data to the FIT files
        		//-------------------------------------------
            	var CoreTemp = sensor.data.CoreTemp;

				if ((sensor.data.isValidCoreTemp(CoreTemp)) && (mCoreTemp != null )) {
	            	// Store core body temp in fit file - add other fields here if necessary
		            //----------------------------------------------------------------------
					if ( mCoreTemp.writeValue( CoreTemp, mTimerRunning, false )) {
			            mCoreTemp.currField.setData( CoreTemp.toFloat());					// write CoreTemp in C
			            
		    	        if( mTimerRunning ) {
		        	        // Updatea average FIT Contributions
		            		mCoreTemp.writeLapSessionValues();
						}
					
						if ((mTHB != null) &&  (mSMO2 != null)) {
							// write CoreTemp into THB and SMO2 moxy fields for backward compatability
	    	        		mTHB.currField.setData( CoreTemp.toFloat() * 100.0);			// Hemoglobin Concentration is stored in 1/100ths g/dL fixed point
	        	    		mSMO2.currField.setData( CoreTemp.toFloat() * 10.0);			// Saturated Hemoglobin Percent is stored in 1/10ths % fixed point
						}
					}
    	        }  // end if valid temp

				// Skin Temp
				//----------
	            var SkinTemp = sensor.data.SkinTemp;
      
    	        if ((mSkinTemp != null) && (mSkinTemp.writeValue( SkinTemp, mTimerRunning, false ))) {
   			    	mSkinTemp.currField.setData(SkinTemp.toFloat());								// write SkinTemp
            	}
			            
				// CORE Data Quality Value
				//------------------------
				var coreSportAlgorithm = sensor.data.usingHeartRate ? 0x10 : 0;
            	var coreQual = sensor.data.dataQuality + coreSportAlgorithm;

	            if ((mCoreQual != null) && (mCoreQual.writeValue( coreQual, mTimerRunning, true ))) {
					mCoreQual.currField.setData(coreQual.toNumber());								// write CORE Data Quality Value
        	    }

				// CORE Reseved Value
				//-------------------            
        	    var coreResv = sensor.data.coreReserved;
            
            	if ((mCoreResv != null) && (mCoreResv.writeValue( coreResv, mTimerRunning, true ))) {
					mCoreResv.currField.setData(coreResv.toNumber());								// write CORE Reserved Value
    	        }
        	}  else if ((mCoreResv != null) && (mCoreResv.writeValue( 0, mTimerRunning, true ))) {	// missing data packets
				mCoreResv.currField.setData( 0x3FFF );												// write marker core_reserved
        	}	// end if
       	}  // end if
    }	// end func compute


    function setTimerRunning( state, sensor ) {
        mTimerRunning = state;

    	if ((state == false) && (sensor != null) && (mConnectIQinfoField != null)) {
    		// write ConnectIQ summary info when timer/session is stopped
    		//-----------------------------------------------------------
    		var deviceConnectIQinfo = new [14];
    		
			deviceConnectIQinfo[0]  = sensor.DEVICE_TYPE;		// device type CORE = 0x7F
    		deviceConnectIQinfo[1]  = 19;						// sensor position - left chest by default = 19
    		
			if ( sensor.data.deviceSerialNumber == 0 ) {
	    		sensor.data.deviceSerialNumber = sensor.ANTid;	// use ANTid for serial number if not set
			}
    		deviceConnectIQinfo[2]  =  sensor.data.deviceSerialNumber & 0x00FF;				// serial number LSB 
    		deviceConnectIQinfo[3]  = (sensor.data.deviceSerialNumber & 0xFF00) >> 8;	 	// serial number 2nd byte 
    		deviceConnectIQinfo[4]  = (sensor.data.deviceSerialNumber & 0x00FF0000) >> 16;	// serial number 3rd byte
    		deviceConnectIQinfo[5]  = (sensor.data.deviceSerialNumber & 0xFF000000) >> 24;	// serial number MSB
    		
    		deviceConnectIQinfo[6]  =  sensor.data.manufactureID & 0x00FF;			// manufacturer LSB  CORE = 303
    		deviceConnectIQinfo[7]  = (sensor.data.manufactureID & 0xFF00) >> 8;	// manufacturer MSB	 CORE = 303
    		
    		deviceConnectIQinfo[8]  = sensor.data.batteryState;						// battery status
    		deviceConnectIQinfo[9]  =  sensor.data.firmwareVersion & 0x00FF;		// software version LSB
    		deviceConnectIQinfo[10] = (sensor.data.firmwareVersion & 0xFF00) >> 8;	// software version MSB

    		deviceConnectIQinfo[11] = sensor.data.hwVersion;						// hardware version
    		deviceConnectIQinfo[12] =  sensor.data.hwModelNumber & 0x00FF;			// product LSB
    		deviceConnectIQinfo[13] = (sensor.data.hwModelNumber & 0xFF00) >> 8;	// product MSB
    		
    		mConnectIQinfoField.setData( deviceConnectIQinfo );
    	}
    }	// end func setTimerRunning


    function onTimerLap() {
        if ( mCoreTemp != null ) {	mCoreTemp.resetLapValue(); }
    }	// end func OnTimerLap


    function onTimerReset() {
        if ( mCoreTemp != null ) {	mCoreTemp.resetSessionValue(); }
    }	// end func OnTimerReset

}  // end class CoreFitContributor
 