//need this to execute before the Extjs library comes into play, so it's just a plain object
var SmsTimer = {
	
	//needs to be set from java in jsp, uniquely identifies this session on this page
	sessionNumber: null,
	
	//sequence number of next timing event to be stored, this is not sent to the database
	//but is used to keep track of the timers specifically in the UI
	counterNumber: 1,
	
	//hash map of all timer instances		
	timers: {},
			
	//pageRenderSequenceNumber
	pageRenderSequenceNumber: null,
	
	//start a timer to be recorded
	//@return intervalNumber for endingTimer
	startTimer: function(intervalCode, extraConfig){
		var currentCounterNumber = SmsTimer.counterNumber;
		SmsTimer.timers[currentCounterNumber] = {
			interval_code: intervalCode,
			start_time: new Date(),
			additional_data_json: {
				start_json: extraConfig
			}
		};
		SmsTimer.counterNumber++;
		return currentCounterNumber;
	},
	
	//end a timer with the intervalNumber returned from the startTimer function
	endTimer: function(intervalNumber, extraConfig){
		var timerInstance = SmsTimer.timers[intervalNumber];
		if(timerInstance)
		{
			timerInstance.start_time = Ext.Date.format(timerInstance.start_time, "Y-m-d H:i:s.u");
			timerInstance.end_time = Ext.Date.format(new Date(), "Y-m-d H:i:s.u");

			if(timerInstance.additional_data_json)
			{
				if(timerInstance.additional_data_json.start_json || extraConfig)
				{
					timerInstance.additional_data_json.end_json = extraConfig;
					timerInstance.additional_data_json = Ext.encode(timerInstance.additional_data_json);//encode the data json into a string
				}
				else
					delete timerInstance.additional_data_json;
			}

			timerInstance.session_number = SmsTimer.sessionNumber;

			//by the point of endTime, the Extjs library should have been initialized, so we can use Ext.Ajax.request
			Ext.Ajax.request({
				url: "ui_timing.jsp",
				success: function(response, opts){
					//delete the object because it is no longer needed
					delete SmsTimer.timers[intervalNumber];
				},
				failure: function(response, opts) {
					//?
				},
				params: timerInstance
			});
		}
	},
	
	//function that makes it easier to call when a page starts rendering
	startPageRenderTimer: function(){
		SmsTimer.pageRenderSequenceNumber = SmsTimer.startTimer("PAGE_RENDER");
	},
	
	//function that makes it easier to call when a page is finished rendering
	endPageRenderTimer: function(){
		if(SmsTimer.pageRenderSequenceNumber)
		{
			SmsTimer.endTimer(SmsTimer.pageRenderSequenceNumber);
			SmsTimer.pageRenderSequenceNumber = null;
		}
	}
};

