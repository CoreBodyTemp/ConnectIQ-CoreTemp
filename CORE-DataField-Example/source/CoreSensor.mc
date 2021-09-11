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

using Toybox.Ant;
using Toybox.Time;
using Toybox.Sensor;


//----------------------------------------------
// CORE AN+ Sensor
//----------------------------------------------
class CoreSensor extends Ant.GenericChannel {
    const DEVICE_TYPE = 0x7F;	// CORE 129 (0x7F)
    const PERIOD = 16384;		// 2Hz transmition rate
	const PAGE_CORE_INFO = 0x00;
	const PAGE_CORE_TEMP = 0x01;
	const PAGE_BATTERY   = 0x52;
	const SENSOR_TIMEOUT = 30;	// in seconds but open sensor as 12 * 2.5 sec = 30
	
	var ANTid = 0;
    var data = null;
    var searching = 0;
    var msgTimeStamp = null;
    
    hidden var sendHrmCnt = 0;
    hidden var chanAssign = null;
	hidden const SEND_HRM_TIMEOUT = 4;


    class CoreData {
		const BATTERY_NOT_SET  = 0;
		const BATTERY_OK       = 3;
		const BATTERY_LOW 	   = 4;
		const BATTERY_CRITICAL = 5;
		hidden var VALID_CORE_TEMP = 24.0;	

        var eventCount = 0;
        var CoreTemp = 0;
	    var SkinTemp = 0;
 		var	dataQuality = 4;
	   	var coreReserved = 0;
	   	var batteryState = BATTERY_NOT_SET;		// = 0
 		var usingHeartRate = false;

	   	var hwVersion = 0;
 		var manufactureID = 0;
		var hwModelNumber = 0;
 		var firmwareVersion = 0;
 		var deviceSerialNumber = 0;
 

		function isValidCoreTemp( temperature ) {
			// check that current temp is valid
			//---------------------------------
			return (temperature > VALID_CORE_TEMP);	// invalid core temp ie. zero
		}   // end func isValidCoreTemp

    }	// end class CoreData


    class CoreDataPage {
		const CORE_OEM_ID = 303;	// CORE developer id = greenTEG
		const ACK_NONE       = 0x00;
		const ACK_UTC_TIME   = 0x01;
		const ACK_HEART_RATE = 0x02;


        function parseCoreSensor(payload, data) {
	        //----------------------------
	        // parse the ANT+ data Message
	        //----------------------------
        	var ackRequest = ACK_NONE;
        	var dataPage = payload[0];

        	switch ( dataPage ) {
        		case 0x00:		{		// transmittion info page
	        		// currently ignored
	        		ackRequest = parseGeneralInfoPage(payload, data);
        			break;
        		}						//----------------------
        		case 0x01:		{		// temperature data page
					parseTemperaturePage(payload, data);
        			break;
        		}	
        		case 0x50:		{	// Manufacturer�s Identification
        			parseManufactureId( payload, data );      			
        			break;
        		}
        		case 0x51:		{	// Product Information
        			parseProductInfo( payload, data );
        			break;
        		}
        		case 0x52:		{	// Battery Status
        			parseBatteryPage(payload, data);
        			break;
        		}
        		case 0x46:			// reqeustion information page - ack from request
        		case 0x53:			// Time and Date
        		case 0x54:			// Subfield Data
        		case 0x55:			// Memory Level
        		case 0x56:			// Paired Devices
        		case 0x57:			// Error Description
        		default:			// ID'S 2 to 63 pages reserved for future use
        			break;
        	}   
        	
        	return ackRequest;     	
        }	// end func parseCoreSensor


	    function twelveBitToSigned(value) {
    	    if(value & 0x0800 == 0x0800) {
        	    value = value | 0xFFFFF000;       	    
        	}

        	return value;
    	}	// end func twelveBitToSigned


    	function sixteenbitToSigned(value) {
        	if(value & 0x8000) {
            	value = value | 0xFFFF0000; 
	        }

    	    return value;
    	}	// end func sixteenbitToSigned


	    function parseGeneralInfoPage(payload, data) {
			//-------------------------
			// General Information Page 
			//-------------------------
			var ackRequest = ACK_NONE;
			       
			// Data Quality: 0= --.--C, 1= #-.--C, 2= ##.--C, 3= ##.#-C, 4= ##.##C
			//--------------------------------------------------------------------
			if ( payload[2] == 0xFF ) {		// reliability of the broadcast data
				data.dataQuality = 4;		// default value - disregard data quality value
			} else if ( data.isValidCoreTemp( data.CoreTemp ) == false ) {
					data.dataQuality = 0;	// Data Quality = 0 if temp is core temp is invalid 
			} else {
				data.dataQuality = payload[2] & 0x03 + 1;	// get the data quality value sent
			}	

			// Heart Rate Request Message
			//---------------------------
			var heartRateSupport = (payload[3] & 0xC0) >> 6;

			if ( heartRateSupport == 1 ) {
				// Heart Rate supported / NOT SET
				data.usingHeartRate = false;

				// Heart Rate not set, Send HR ANT ID or Data
				ackRequest = ACK_HEART_RATE;
			} else if ( heartRateSupport == 2 ) {
				// Heart Rate supported and SET
				data.usingHeartRate = true;
			}			
			 
			// UTC Time Message - request 
			// Local Time Message - N/A
			//---------------------------
			var utcRequest = (payload[3] & 0x0C) >> 2;
			
			if ( utcRequest == 1 ) {
				// UTC not set, send set UTC message
				ackRequest = ACK_UTC_TIME;
			}

			return ackRequest;			 
		}  // end func parseGeneralInfoPage
		

	    function parseTemperaturePage(payload, data) {
			//------------------------------------------------------       
			// Temperature Data: CORE Temp, Skin Temp, coreReserved
			//------------------------------------------------------
			data.eventCount = payload[2].toNumber();
			  
	        data.SkinTemp  = twelveBitToSigned( ((payload[4] & 0xF0) << 4) | payload[3] );
	        if ( data.SkinTemp == -32768 )	{		   // 0X8000
	        	data.SkinTemp = 0.0;				   // invalid Temp
	        } else {
	        	data.SkinTemp = data.SkinTemp / 20.0;  // data stored as SkinTemp * 2 * 10 for 0.05 accuracy
	        }
	        
	        data.coreReserved = twelveBitToSigned( (payload[5] << 4) | (payload[4] & 0x0F) );
	        if ( data.coreReserved == -32768 )	{		     // 0X8000
	        	data.coreReserved = 0;					     // invalid Value
	        } else {
	        	data.coreReserved = data.coreReserved / 1;   // not defined yet
	        }

	        //-----------------
	        // CORE Temperature
	        //-----------------
	        var newTemperature = sixteenbitToSigned( (payload[7] << 8) | payload[6] );
	        if ( newTemperature == -32768 )	{		// 0X8000
	        	newTemperature = 0.0;				// invalid Temp
	        } else {
	        	newTemperature = newTemperature / 100.0;
	        }

			data.CoreTemp = newTemperature;
	    }	// end func parseTemperaturePage

	    
	    function parseBatteryPage(payload, data) {
			// Battery Status message
			//-----------------------
			// 0 Reserved for future use
			// 0   also Battery not set
			// 1 Battery Status = New
			// 2 Battery Status = Good
			// 3 Battery Status = Ok
			// 4 Battery Status = Low
			// 5 Battery Status = Critical
			// 6 Reserved for future use				    	
			// 7 Invalid
	    	data.batteryState = (payload[7] & 0x70) >> 4;

			if ((data.batteryState < 1) || (data.batteryState > 5)) {
				data.batteryState = data.BATTERY_OK;		// invalid or unsported battery voltage - so ignore by saying status is Ok
			}
	    }	// end func parseBatteryPage


	    function parseManufactureId(payload, data) {
			// manufacture id is 303 from CORE
			//--------------------------------
			data.hwVersion = payload[3];
			data.manufactureID = ((payload[5] & 0x00FF) << 8) | (payload[4] & 0x00FF);
			data.hwModelNumber = ((payload[7] & 0x00FF) << 8) | (payload[6] & 0x00FF);

			if ( data.manufactureID == CORE_OEM_ID ) {
				// it is a CORE device Device ID = 303
				// manufacture specific requests here
			}
	    }	// end func parseManufactureId
    

	    function parseProductInfo(payload, data) {
			// get the firmware version and serial number
			//-------------------------------------------
			if ( payload[2] == 255 ) {	
				data.firmwareVersion = payload[3];							// simple version / 10
			} else {
				data.firmwareVersion = (payload[3] * 100) + payload[2];		// = version / 1000
			}

			data.deviceSerialNumber = (payload[7] << 24) + (payload[6] << 16) + (payload[5] << 8) + payload[4];
	    }	// end func parseProductInfo
	    	
	}  // end class CoreDataPage

 
    function initialize() {
    	// setup the ANT CORE channel
    	//---------------------------
    	if ( chanAssign == null ) {
	        // Get the channel
	        chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PLUS);
	        
	        if ( chanAssign != null ) {
	        	GenericChannel.initialize(method(:onMessage), chanAssign);
	        }
		}
		
		ANTid = CoreSettings.getCoreAntId();	// Get the Stored CORE ANT+ device ID from the settings
		sendHrmCnt = 0;							// only send the 0x4A HRM id x times
		startSearch();							// start searching for CORE Sensor!
		msgTimeStamp = Time.now();

        // Set the configuration
        var deviceCfg;

        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => ANTid,             // 0 = Wildcard search
            :deviceType => DEVICE_TYPE,
            :transmissionType => 0,
            :messagePeriod => PERIOD,
            :radioFrequency => 57,              // Ant+ Frequency
            :searchTimeoutLowPriority => 12,    // Timeout in X*2.5s
            :searchTimeoutHighPriority => 0,    // disabled
            :searchThreshold => 0} );           // Pair to all transmitting sensors
        if ( deviceCfg != null ) {
        	GenericChannel.setDeviceConfig(deviceCfg);
        }
 
 		if ( data == null ) {
	        data = new CoreData();
	    }
    }	// end func initilize


    function open() {
        // Open the CORE ANT+ channel
        //---------------------------
        startSearch();

        GenericChannel.open();
        data = new CoreData();
    }	// end func open


    function closeSensor() {
        // Close the CORE ANT+ channel
        //-----------------------------
        GenericChannel.close();
    }	// end func closeSensor
    

	function sendAckMessage(ackRequest, dataPage)  {
		// Send messages Back to the CORE device
		//--------------------------------------
        if ( ackRequest & dataPage.ACK_HEART_RATE ) {
        	// send the HR ANTid to the CORE device
			sendHeartRateToCore();
		}
		
        if ( ackRequest & dataPage.ACK_UTC_TIME ) {
        	// send UTC Time to the CORE device
			setCoreUTCtime();			
		}
	}	// end func sendAckMessage	       


    function sendHeartRateToCore() {
        // send the Paired Heart Rate monitor ANTid to the CORE device
        //------------------------------------------------------------
        var hrmID = CoreSettings.getPairedHrmId();
            
        if ( !searching && (hrmID != 0) && (sendHrmCnt < SEND_HRM_TIMEOUT)) {
	        var payload = new [8];
	        payload[0] = 0x4A;  // Send Open Channel Command
	            
	        payload[1] =  hrmID & 0x0000FF;  		// HR AntID Serial Number (LSB)
	        payload[2] =  hrmID & 0x00FF00 >> 8;	// HR AntID Serial
			payload[3] = (hrmID & 0xF00000) >> 4;	// Transmittion Type + long ANTid

	        payload[4] = 120;						// HRM Device Type
	        payload[5] = 57;						// RF Frequency
	        payload[6] = 8070 & 0x00FF;     		// Channel Period (LSB)
	        payload[7] = 8070 & 0xFF00 >> 8;		// Channel Period (MSB)

	        // Form and send the message
    	    //--------------------------
        	var message = new Ant.Message();
        	    
            if ( message != null ) {
            	sendHrmCnt = sendHrmCnt + 1;
	          	message.setPayload(payload);
	    	    GenericChannel.sendAcknowledge(message);
    	    }
		}
    }	// end func sendHeartRateToCore


    function setCoreUTCtime() {
    	// upon request - send CORE current UTC time
    	//------------------------------------------
        if( !searching ) {
	        //Create and populat the data payload
	        var payload = new [8];
	        
	        payload[0] = 0x10;  // Command data page
	        payload[1] = 0x00;  // Set time command
	        payload[2] = 0xFF;  // Reserved
	        payload[3] = 0;     // Signed 2's complement value indicating local time offset in 15m intervals
		
	        //Set the current time
	        var moment = Time.now();
	        for (var i = 0; i < 4; i++) {
	        	payload[i + 4] = ((moment.value() >> i) & 0x000000FF);
	        }
		
	        //Form and send the message
	        var message = new Ant.Message();
	        if ( message != null ) {
		        message.setPayload(payload);
	    	    GenericChannel.sendAcknowledge(message);
	    	}
        }
    }	// end func setCoreUTCtime


    function requestPage( pageNum ) {
    	// upon request - send CORE current UTC time
    	//------------------------------------------
        if( !searching ) {
	        //Create and populat the data payload
	        var payload = new [8];
	        
	        payload[0] = 0x46;  	// Request data page
	        payload[1] = 0xFF;  	// serial number - not needed
	        payload[2] = 0xFF;  	// serial number - not needed
	        payload[3] = 0xFF;     	// Descriptor Byte 1 - not needed
	        payload[4] = 0xFF;		// Descriptor Byte 1- not needed
	        payload[5] = 1;			// Requested Transmission Response - 1 message requested

	        payload[6] = pageNum;   // Page number would like to receive
	        payload[7] = 0x01;		// Request Data Page command
		
	        //Form and send the message
	        var message = new Ant.Message();
	        if ( message != null ) {
		        message.setPayload(payload);
	    	    GenericChannel.sendAcknowledge(message);
	    	}
        }
    }	// end func requestPage


	function startSearch() {
		if ( !searching ) {
			searching = 1;
		}
	}	// end func stopSearch

	
	function stopSearch() {
		searching = 0;
	}	// end func stopSearch
	

    function onMessage(msg) {
        //-------------------------------
        // Parse the ANT+ message payload
        //-------------------------------
        var payload = msg.getPayload();
		msgTimeStamp = Time.now();

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId ) {
        	if( searching ) {
                stopSearch();

				if ( ANTid == 0 ) {
					CoreSettings.setCoreAntId(msg.deviceNumber);	// save the ANT id if none or updated
				}			
            }
       
            var dp = new CoreDataPage();
            if ( dp != null ) {
            	var ackRequest = dp.parseCoreSensor(msg.getPayload(), data);

				if ( ackRequest != dp.ACK_NONE ) {
					sendAckMessage(ackRequest, dp);
				}          
	        }
        } else if(Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) {
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) {
                    // Channel closed, re-open
                    open();
                } else if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF) ) {
					startSearch();		// search again?
                }
            } else {
                // channel response not handled
            }
        }
    }	// end func OnMessage

}	// end class CoreSensor
