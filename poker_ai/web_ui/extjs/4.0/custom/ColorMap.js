/**
 * Collection of standard colors to be used with charts, etc.
 */
Ext.define("Sms.ColorMap", {
	extend:    "Ext.util.MixedCollection",
	singleton: true,

	constructor: function(){
		var me = this;
		me.callParent();

		me.addAll([
			{name: "darkblue",  color: "#005290"},
			{name: "darkgray",  color: "#696969"},
			{name: "green",     color: "#4E8542"},
			{name: "red",       color: "#9F2936"},
			{name: "orange",    color: "#F07F09"},
			{name: "purple",    color: "#604878"},
			{name: "gold",      color: "#DAA520"},
			{name: "teal",      color: "#008B8B"},
			{name: "tan",       color: "#887952"},
			{name: "blue",      color: "#4F81BD"},
			{name: "lightblue", color: "#C6D9F1"},
			{name: "gray",      color: "#D9D9D9"},
			{name: "lightgray", color: "#BFBFBF"},
			{name: "black",     color: "#000000"},
			{name: "white",     color: "#FFFFFF"}
		]);
	},

	getKey: function(o){
		return o.name || null;
	},

	/**
	 * Get the RGB color value by name or index.
	 *
	 * @param {String/Number} input the name of the color, or the index in the collection
	 * @return {String} the RGB color string
	 */
	getColor: function(input){
		var me    = this;
		var color = Ext.isNumber(input) ? me.getAt(input) : me.getByKey(input);
		return color && color.color;
	},

	/**
	 * Get all RGB color values.
	 *
	 * @return {String[]} the RGB color values
	 */
	getAllColors: function(){
		return this.collect("color");
	}
});
