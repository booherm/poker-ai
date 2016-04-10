(function(Highcharts){

	var Chart  = Highcharts.Chart;
	var extend = Highcharts.extend;
	var merge  = Highcharts.merge;

	function correctFloat(num){
		return parseFloat(num.toPrecision(14));
	}

	function defined(val){
		return val !== null && typeof val !== "undefined";
	}

	function arrayMin(data) {
		var i = data.length,
			min = data[0];

		while (i--) {
			if (data[i] < min) {
				min = data[i];
			}
		}
		return min;
	}

	function arrayMax(data) {
		var i = data.length,
			max = data[0];

		while (i--) {
			if (data[i] > max) {
				max = data[i];
			}
		}
		return max;
	}

	function pick() {
		var args = arguments,
			i,
			arg,
			length = args.length;
		for (i = 0; i < length; i++) {
			arg = args[i];
			if (typeof arg !== 'undefined' && arg !== null) {
				return arg;
			}
		}
	}

	// Uses "smsMin" and "smsMax" to set a flexible axis range.
	Highcharts.wrap(
		Highcharts.Axis.prototype,
		"getLinearTickPositions",
		function(orig, tickInterval, min, max){
			var axis    = this;
			var options = axis.options;
			var smsMin  = options.smsMin;
			var smsMax  = options.smsMax;
			var range   = options.minRange;

			axis.min = defined(smsMin) ? Math.max(smsMin, min) : min;
			axis.max = defined(smsMax) ? Math.min(smsMax, max) : max;

			if(range && range > (axis.max - axis.min)){
				if(defined(smsMax) && !defined(smsMin)){
					axis.min = axis.max - range;
				}
				else{
					axis.max = axis.min + range;
				}
			}

			return orig.call(axis, tickInterval, axis.min, axis.max);
		}
	);

	Highcharts.setOptions({
		chart: {
			animation:    false,
			borderColor:  "#2466B1",
			borderRadius: 11,
			borderWidth:  2
		},
		colors: Sms.ColorMap.getAllColors(),
		credits: {
			enabled: false
		},
		exporting: {
			url:     "mrd_highcharts_image.jsp",
			buttons: {
				contextButton: {
					menuItems: [{
						textKey: "downloadPNG",
						onclick: function(){
							this.smsExportChart();
						}
					}]
				}
			}
		},
		legend: {
			itemDistance: 20,
			itemStyle: {
				color: "#000"
			}
		},
		plotOptions: {
			area: {
				trackByArea: true,
				marker: {
					enabled: false
				}
			},
			arearange: {
				tooltip: {
					pointFormat: "{point.low} - {point.high}"
				}
			},
			bar: {
				borderWidth:  0,
				groupPadding: 0.16,
				pointPadding: 0,
				shadow:       true
			},
			column: {
				borderWidth:  0,
				groupPadding: 0.16,
				pointPadding: 0,
				shadow:       true
			},
			pie: {
				dataLabels: {
					color:          "#000",
					connectorColor: "#000"
				}
			},
			series: {
				animation: false,
				threshold: null
			}
		},
		title: {
			style: {
				color: "#005290",
				font:  "bold 16px Arial, sans-serif"
			}
		},
		tooltip: {
			pointFormat: "{point.y}"
		},
		subtitle: {
			style: {
				color: "#005290",
				font:  "bold 12px Arial, sans-serif"
			}
		},
		xAxis: {
			gridLineColor:      "#C1C1C1",
			gridLineWidth:      1,
			lineColor:          "#000",
			minorGridLineColor: "#EEE",
			minorGridLineWidth: 1,
			minorTickLength:    3,
			tickColor:          "#000",
			tickmarkPlacement:  "between",
			labels: {
				align:    "right",
				rotation: 315,
				style: {
					color: "#000",
					font:  "11px Helvetica, sans-serif"
				}
			},
			title: {
				margin: 15,
				style: {
					color: "#000",
					font:  "bold 12px Arial, sans-serif"
				}
			},
			type: "category"
		},
		yAxis: {
			alternateGridColor: "#FAFAFA",
			gridLineColor:      "#C1C1C1",
			gridLineWidth:      1,
			lineColor:          "#000",
			lineWidth:          1,
			minorGridLineColor: "#EEE",
			minorGridLineWidth: 1,
			minorTickInterval:  "auto",
			minorTickLength:    3,
			minorTickWidth:     1,
			minRange:           1,
			tickColor:          "#000",
			tickWidth:          1,
			labels: {
				style: {
					color: "#000",
					font:  "11px Helvetica, sans-serif"
				}
			},
			title: {
				style: {
					color: "#000",
					font:  "bold 12px Arial, sans-serif"
				}
			}
		}
	});

	extend(Chart.prototype, {
		smsExportChart: function(options, chartOptions){
			options = options || {};

			var chart         = this;
			var exportOptions = chart.options.exporting;

			var chartSize = (function getChartSize(chart){
				var cssWidth  = chart.renderTo.style.width;
				var cssHeight = chart.renderTo.style.height;
				var pxRegExp  = /px$/;

				var size = {
					width:  (pxRegExp.test(cssWidth) && parseInt(cssWidth, 10)),
					height: (pxRegExp.test(cssHeight) && parseInt(cssHeight, 10))
				};

				return size;
			}(chart));

			var outputWidth  = (chartSize.width || exportOptions.width);
			var outputHeight = (chartSize.height || exportOptions.height);

			var svg = chart.getSVG(merge(
				exportOptions,
				chartOptions,
				{
					exporting: {
						sourceWidth:  outputWidth,
						sourceHeight: outputHeight
					}
				}
			));

			options = merge(chart.options.exporting, options);

			Sms.Ajax.request({
				url:     options.url,
				timeout: 60000,
				type:    "POST",
				data:    {
					width:  outputWidth,
					height: outputHeight,
					svg:    Sms.Base64.encode(svg, true)
				},
				success: function(response){
					Sms.file.viewAttachment({
						context:   "HCCHART_IMAGE",
						file_name: response.filename
					});
				},
				error: function(){
					Ext.Msg.alert("Image Error", "Sorry, an error occurred while generating the chart image.");
				}
			});
		}
	});

}(Highcharts));
