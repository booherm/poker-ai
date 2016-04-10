/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

Ext.override(Gnt.data.Calendar, {
	calculateDuration : function (startDate, endDate, unit) {
		var duration = 0;
		
		if(Ext.isDate(startDate) && Ext.isDate(endDate))
		{
		
			if (startDate > endDate) Ext.Error.raise("startDate can't be bigger than endDate");

			this.forEachAvailabilityInterval(startDate, endDate, function (interval) {
				var intervalStartDate       = interval.startDate
				var intervalEndDate         = interval.endDate

				// availability interval is out of [ startDate, endDate )
				if (intervalStartDate > endDate || intervalEndDate < startDate) return

				var countingFrom            = intervalStartDate > startDate ? intervalStartDate : startDate
				var countingTill            = intervalEndDate > endDate ? endDate : intervalEndDate

				duration                    += countingTill - countingFrom
			});
		}
            
        return this.convertMSDurationToUnit(duration, unit);
    }
});

Ext.define("Gnt.template.CustomParentTaskTemplate", {
    extend : 'Ext.XTemplate',

    constructor : function (cfg) {
        this.callParent([
                 '<div class="sch-event-wrap ' + cfg.baseCls + ' x-unselectable" style="left:{leftOffset}px;">' +
                    // Left label 
                    (cfg.leftLabel ? '<div class="sch-gantt-labelct sch-gantt-labelct-left"><label class="sch-gantt-label sch-gantt-label-left">{leftLabel}</label></div>' : '')+
                    
                    // Task bar
                    '<div id="' + cfg.prefix + '{id}" class="sch-gantt-item sch-gantt-task-bar-custom {internalcls} {cls}" unselectable="on" style="width:{width}px;{style}">'+
                        // Left terminal
                        (cfg.enableDependencyDragDrop ? '<div unselectable="on" class="sch-gantt-terminal sch-gantt-terminal-start"></div>' : '') +
                        ((cfg.resizeHandles === 'both' || cfg.resizeHandles === 'left') ? '<div class="sch-resizable-handle sch-gantt-task-handle sch-resizable-handle-west"></div>' : '') +
                
                        '<div class="sch-gantt-progress-bar" style="width:{percentDone}%;{progressBarStyle}" unselectable="on">&#160;</div>' +

                        ((cfg.resizeHandles === 'both' || cfg.resizeHandles === 'right') ? '<div class="sch-resizable-handle sch-gantt-task-handle sch-resizable-handle-east"></div>' : '') +
                        // Right terminal
                        (cfg.enableDependencyDragDrop ? '<div unselectable="on" class="sch-gantt-terminal sch-gantt-terminal-end"></div>' : '') +
                        (cfg.enableProgressBarResize ? '<div style="left:{percentDone}%" class="sch-gantt-progressbar-handle"></div>': '') +
                    '</div>' +
                   
                    // Right label 
                    (cfg.rightLabel ? '<div class="sch-gantt-labelct sch-gantt-labelct-right" style="left:{width}px"><label class="sch-gantt-label sch-gantt-label-right">{rightLabel}</label></div>' : '') +
                '</div>',
            {
                compiled: true,      
                disableFormats: true 
            }
        ]);
    }
});

Ext.override(Gnt.Tooltip, {
	getDurationContent : function(start, end, valid, taskRecord) {
        var unit        = taskRecord.getDurationUnit() || Sch.util.Date.DAY;
        var duration    = 0;
		
		try{
			duration = taskRecord.calculateDuration(start, end, unit);
		}catch(e){
			//this is a tooltip. I don't need it to error out on calculation of a display value...
			duration = 0;
		}
        
        return this.durationTemplate.apply({
            cls         : valid ? 'sch-tip-ok' : 'sch-tip-notok',
            startText   : this.gantt.getFormattedDate(start),
            duration    : parseFloat(Ext.Number.toFixed(duration, 1)),
            unit        : Sch.util.Date.getReadableNameOfUnit(unit, duration > 1)
        });
    }
});

Ext.override(Gnt.view.Gantt, {
	
	setupTemplates: function () {

        var tplCfg = {
            leftLabel : !!this.leftLabelField,
            rightLabel : !!this.rightLabelField,
            prefix : this.eventPrefix,
            enableDependencyDragDrop: this.enableDependencyDragDrop !== false,
            resizeHandles: this.resizeHandles,
            enableProgressBarResize: this.enableProgressBarResize
        };

        if (!this.eventTemplate) {
            tplCfg.baseCls = "sch-gantt-task {ctcls}";
            this.eventTemplate = Ext.create("Gnt.template.Task", tplCfg);
        }

        if (!this.parentEventTemplate) {
            tplCfg.baseCls = "sch-gantt-task {ctcls}";
            this.parentEventTemplate = Ext.create("Gnt.template.CustomParentTaskTemplate", tplCfg);
        }

        if (!this.milestoneTemplate) {
            tplCfg.baseCls = "sch-gantt-milestone {ctcls}";
            this.milestoneTemplate = Ext.create("Gnt.template.Milestone", tplCfg);
        }

        if (this.enableBaseline) {    
            tplCfg = { 
                prefix : this.eventPrefix
            };
            if (!this.baselineTaskTemplate) {
                tplCfg.baseCls = "sch-gantt-task-baseline sch-gantt-baseline-item {basecls}";
                this.baselineTaskTemplate = Ext.create("Gnt.template.Task", tplCfg);
            }

            if (!this.baselineParentTaskTemplate) {
                tplCfg.baseCls = "sch-gantt-task-baseline sch-gantt-baseline-item {basecls}";
                this.baselineParentTaskTemplate = Ext.create("Gnt.template.Task", tplCfg);
            }

            if (!this.baselineMilestoneTemplate) {
                tplCfg.baseCls = "sch-gantt-milestone-baseline sch-gantt-baseline-item {basecls}";
                this.baselineMilestoneTemplate = Ext.create("Gnt.template.Milestone", tplCfg);
            }
        }
    },
	
	// private
    renderTask: function (taskModel) {
        var taskStart = taskModel.getStartDate(),
			taskEnd = taskModel.getEndDate(),
            ta = this.timeAxis,
            D = Sch.util.Date,
            tplData = {},
            cellResult = '',
            viewStart = ta.getStart(),
            viewEnd = ta.getEnd(),
            isMilestone = taskModel.isMilestone(),
            isLeaf = taskModel.isLeaf(),
            userData, startsInsideView, endsOutsideView;
            
        if (taskStart && taskEnd) {
            var doRender = Sch.util.Date.intersectSpans(taskStart, taskEnd, viewStart, viewEnd);

            if (doRender) {
                endsOutsideView = taskEnd > viewEnd;
                startsInsideView = D.betweenLesser(taskStart, viewStart, viewEnd);

                var taskStartX = Math.floor(this.getXYFromDate(startsInsideView ? taskStart : viewStart)[0]),
                    itemWidth = isMilestone ? 0 : Math.floor(this.getXYFromDate(endsOutsideView ? viewEnd : taskEnd)[0]) - taskStartX;

                //if (!isMilestone && !isLeaf) {
                //    itemWidth += 12; // Compensate for the parent arrow offset (6px on both sides)
                //}

                tplData = {
                    // Core properties
                    id: taskModel.internalId,
                    leftOffset: taskStartX,
                    internalcls: (taskModel.dirty ? ' sch-dirty ' : '') + (taskModel.getCls() || ''),
                    width : Math.max(1, itemWidth),

                    // Percent complete
                    percentDone: taskModel.getPercentDone() || 0
                };

                // Get data from user "renderer" 
                userData = this.eventRenderer.call(this, taskModel, tplData, taskModel.store) || {};
                var lField = this.leftLabelField,
                    rField = this.rightLabelField,
                    tpl;

                if (lField) {
                    // Labels
                    tplData.leftLabel = lField.renderer.call(lField.scope || this, taskModel.data[lField.dataIndex], taskModel);
                }

                if (rField) {
                    tplData.rightLabel = rField.renderer.call(rField.scope || this, taskModel.data[rField.dataIndex], taskModel);
                }

                Ext.apply(tplData, userData);

                if (isMilestone) {
                    tpl = this.milestoneTemplate;
                } else {
                    tplData.width = Math.max(1, itemWidth);

                    if (endsOutsideView) {
                        tplData.internalcls += ' sch-event-endsoutside ';
                    }

                    if (!startsInsideView) {
                        tplData.internalcls += ' sch-event-startsoutside ';
                    }
                    tpl = this[isLeaf ? "eventTemplate" : "parentEventTemplate"];
                }

                cellResult += tpl.apply(tplData);
            }
        }
        
        if (this.enableBaseline) {
            
            var taskBaselineStart = taskModel.getBaselineStartDate(),
                taskBaselineEnd = taskModel.getBaselineEndDate();

            if (!userData) {
                userData = this.eventRenderer.call(this, taskModel, tplData, taskModel.store) || {};
            }
            
            if (taskBaselineStart && taskBaselineEnd) {
				//added this line so baselines don't become milestones in the case where the task is a baseline
                isMilestone = taskBaselineStart == taskBaselineEnd;
				//end addition
                endsOutsideView = taskBaselineEnd > viewEnd;
                startsInsideView = D.betweenLesser(taskBaselineStart, viewStart, viewEnd);
                
                var baseTpl = isMilestone ? this.baselineMilestoneTemplate : (taskModel.isLeaf() ? this.baselineTaskTemplate : this.baselineParentTaskTemplate),
                    baseStartX = Math.floor(this.getXYFromDate(startsInsideView ? taskBaselineStart : viewStart)[0]),
                    baseWidth = isMilestone ? 0 : Math.floor(this.getXYFromDate(endsOutsideView ? viewEnd : taskBaselineEnd)[0]) - baseStartX;
                    
                cellResult += baseTpl.apply({
                    basecls : userData.basecls || '',
                    id: taskModel.internalId + '-base',
                    percentDone: taskModel.getBaselinePercentDone(),
                    leftOffset: baseStartX,
                    width: Math.max(1, baseWidth),
					//added these two lines so we can colorize baselines
					progressBarStyle: userData.baselineProgressBarStyle,
					style: userData.baselineStyle
					//end addition
                });
            }
        }

        return cellResult;
    }
});

Ext.override(Gnt.data.TaskStore, {
	getTotalTimeSpan : function() {
        var earliest = new Date(9999,0,1), latest = new Date(0), D = Sch.util.Date;
        
        this.getRootNode().cascadeBy(function(r) {
            if (r.getStartDate()) {
                earliest = D.min(r.getStartDate(), earliest);
            }
			if (r.getBaselineStartDate())
			{
				earliest = D.min(r.getBaselineStartDate(), earliest);
			}
            if (r.getEndDate()) {
                latest = D.max(r.getEndDate(), latest);
            }
			if (r.getBaselineEndDate()) {
                latest = D.max(r.getBaselineEndDate(), latest);
            }
        });

        earliest = earliest < new Date(9999,0,1) ? earliest : null;
        latest = latest > new Date(0) ? latest : null;

        return {
            start : earliest,
            end : latest || earliest || null
        };
    }
});

//fix for thin bars growing to full row size when resized
Ext.override(Gnt.feature.TaskResize, {
	elementHeight: null,
	createResizable: function (el, taskRecord, e) {
		this.elementHeight = el.getHeight();
		this.callOverridden(arguments);
	},
	partialEastResize : function (resizer, newWidth, oldWidth, e) {
		resizer.getEl().setHeight(this.elementHeight);
		this.callOverridden(arguments);
	},
	partialWestResize : function (resizer, newWidth, oldWidth, e) {
		resizer.getEl().setHeight(this.elementHeight);
		this.callOverridden(arguments);
	}
});