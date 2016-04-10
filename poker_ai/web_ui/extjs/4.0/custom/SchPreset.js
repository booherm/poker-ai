Sch.preset.Manager.registerPreset("weekAndDayLetterSMS", {
	timeColumnWidth : 140,
	rowHeight: 24,          // Only used in horizontal orientation
	resourceColumnWidth : 100,  // Only used in vertical orientation
	displayDateFormat : 'm/d/Y',
	shiftUnit : "WEEK",
	shiftIncrement : 1,
	defaultSpan : 10,       // By default, show 10 weeks
	timeResolution : {
		unit : "DAY",
		increment : 1
	},
	headerConfig : {
		 bottom : {
			unit : "WEEK",
			increment : 1,
			renderer : function() {
				return Sch.util.HeaderRenderers.dayLetter.apply(this, arguments);
			}
		},
		middle : {
			unit : "WEEK",
			dateFormat : 'm/d/Y',
			align : 'left'
		}
	}
});

Sch.preset.Manager.registerPreset("weekAndMonthSMS", {
	timeColumnWidth : 100,
	rowHeight: 24,          // Only used in horizontal orientation
	resourceColumnWidth : 100,  // Only used in vertical orientation
	displayDateFormat : 'm/d/Y',
	shiftUnit : "WEEK",
	shiftIncrement : 5,
	defaultSpan : 6,       // By default, show 6 weeks
	timeResolution : {
		unit : "DAY",
		increment : 1
	},
	headerConfig : {
		middle : {
			unit : "WEEK",
			renderer : function(start, end, cfg) {
				cfg.align = 'left';
				return Ext.Date.format(start, 'm/d');
			}
		},
		top : {
			unit : "MONTH",
			dateFormat : 'm/Y'
		}
	}
});

Sch.preset.Manager.registerPreset("monthAndYearSMS", {
	timeColumnWidth : 110,
	rowHeight: 24,          // Only used in horizontal orientation
	resourceColumnWidth : 100,  // Only used in vertical orientation
	displayDateFormat : 'm/d/Y',
	shiftIncrement : 3,
	shiftUnit : "MONTH",
	defaultSpan : 12,       // By default, show 12 months
	timeResolution : {
		unit : "DAY",
		increment : 1
	},
	headerConfig : {
		middle : {
			unit : "MONTH",
			dateFormat : 'M'
		},
		top : {
			unit : "YEAR",
			dateFormat : 'Y'
		}
	}
});

Sch.preset.Manager.registerPreset("yearSMS", {
	timeColumnWidth : 100,
	rowHeight: 24,          // Only used in horizontal orientation
	resourceColumnWidth : 100,  // Only used in vertical orientation
	displayDateFormat : 'm/d/Y',
	shiftUnit : "YEAR",
	shiftIncrement : 1,
	defaultSpan : 1,       // By default, show 1 year
	timeResolution : {
		unit : "MONTH",
		increment : 1
	},
	headerConfig : {
		bottom : {
			unit : "QUARTER",
			renderer : function(start, end, cfg) {
				return Ext.String.format(Sch.util.Date.getShortNameOfUnit("QUARTER").toUpperCase() + '{0}', Math.floor(start.getMonth() / 3) + 1);
			}
		},
		middle : {
			unit : "YEAR",
			dateFormat : 'Y'
		}
	}
});

Sch.preset.Manager.registerPreset("hoursSMS", {
	timeColumnWidth : 60,   // Time column width (used for rowHeight in vertical mode)
	rowHeight: 24,          // Only used in horizontal orientation
	resourceColumnWidth : 100,  // Only used in vertical orientation
	displayDateFormat : 'g:i A',  // Controls how dates will be displayed in tooltips etc
	shiftIncrement : 1,     // Controls how much time to skip when calling shiftNext and shiftPrevious.
	shiftUnit : "HOUR",      // Valid values are "MILLI", "SECOND", "MINUTE", "HOUR", "DAY", "WEEK", "MONTH", "QUARTER", "YEAR".
	defaultSpan : 12,       // By default, if no end date is supplied to a view it will show 12 hours
	timeResolution : {      // Dates will be snapped to this resolution
		unit : "MINUTE",    // Valid values are "MILLI", "SECOND", "MINUTE", "HOUR", "DAY", "WEEK", "MONTH", "QUARTER", "YEAR".
		increment : 30
	},
	headerConfig : {    // This defines your header, you must include a "middle" object, and top/bottom are optional. For each row you can define "unit", "increment", "dateFormat", "renderer", "align", and "scope"
		middle : {              
			unit : "HOUR",
			dateFormat : 'g:i A'
		},
		top : {
			unit : "DAY",
			dateFormat : 'D d/m',
			renderer: function(){
				return "Time Of Day";
			}
		}
	}
});

Sch.preset.Manager.registerPreset("hours15SMS", {
	timeColumnWidth : 60,   // Time column width (used for rowHeight in vertical mode)
	rowHeight: 24,          // Only used in horizontal orientation
	resourceColumnWidth : 100,  // Only used in vertical orientation
	displayDateFormat : 'g:i A',  // Controls how dates will be displayed in tooltips etc
	shiftIncrement : 1,     // Controls how much time to skip when calling shiftNext and shiftPrevious.
	shiftUnit : "HOUR",      // Valid values are "MILLI", "SECOND", "MINUTE", "HOUR", "DAY", "WEEK", "MONTH", "QUARTER", "YEAR".
	defaultSpan : 12,       // By default, if no end date is supplied to a view it will show 12 hours
	timeResolution : {      // Dates will be snapped to this resolution
		unit : "MINUTE",    // Valid values are "MILLI", "SECOND", "MINUTE", "HOUR", "DAY", "WEEK", "MONTH", "QUARTER", "YEAR".
		increment : 15
	},
	headerConfig : {    // This defines your header, you must include a "middle" object, and top/bottom are optional. For each row you can define "unit", "increment", "dateFormat", "renderer", "align", and "scope"
		middle : {              
			unit : "HOUR",
			dateFormat : 'g:i A'
		},
		top : {
			unit : "DAY",
			dateFormat : 'D d/m',
			renderer: function(){
				return "Time Of Day";
			}
		}
	}
});