/**
 * @class Sms.util.TableGenerator
 * @author Eric Cook
 * @singleton
 *
 * The TableGenerator class makes it easier to create HTML tables and XTemplates
 * from a specification.
 *
 * # TableGenerator layout specification object
 *
 * A specification object is used when creating tables. It describes the column
 * styles, field labels and associated data index names, and related options.
 * The recognized specification properties are:
 *
 * - **id** - The ID of the table. If omitted, uses {@link Ext#id} to create a
 *   unique ID.
 * - **tableCls/tableStyle** - CSS classes and styles to apply to the base table.
 * - **rowCls/rowStyle** - Classes and styles to apply to even-numbered rows.
 * - **altRowCls/altRowStyle** - Classes and styles to apply to odd-numbered rows.
 * - **fields** - An array of field specification objects.
 * - **columns** - An array of column specification objects.
 * - **renderers** - An object of named renderer functions.
 *
 * # Field specification object
 *
 * Each field specification has the following properties:
 *
 * - **label** - The text label to display on the left side of the field.
 * - **name** - The name of the data property to fill the field value with. This
 *   is used when applying data to the {@link Ext.Xtemplate}.
 * - **renderer** - The name of the renderer function to invoke for the value of
 *   the field. See the section titled "Renderer functions" below.
 *
 * # Column specification object
 *
 * Each column specification has the following properties:
 *
 * - **labelCls/labelStyle** - Classes and styles to apply to label cells.
 * - **textCls/textStyle** - Classes and styles to apply to text cells.
 *
 * # Renderer functions
 *
 * Each key in the renderers object is the name of a renderer function. Each
 * renderer function accepts the following arguments:
 *
 * - **value** - The value of the data record for the given field name.
 * - **name** - The name of the field being rendered.
 * - **data** - The data object supplied to the template.
 * - **tpl** - The template instance.
 *
 * The return value of a renderer function is an HTML string to directly insert
 * into the generated markup.
 *
 * # Example
 *
 * The following example demonstrates how to use the TableGenerator to create
 * the content for a {@link Ext.panel.Panel panel}:
 *
 *     // Specification object
 *     var spec = {
 *         id:         'my_table',
 *         tableStyle: 'width:100%',
 *         altRowCls:  'alt-row',
 *         fields: [
 *             {label: 'Customer Name', name: 'customer_nm', colspan: 2},
 *             {label: 'Customer ID',   name: 'customer_id'},
 *             {label: 'Telephone',     name: 'phone_number', renderer: 'phoneNumber'}
 *         ],
 *         columns: [
 *             {
 *                 labelStyle: 'font-weight:bold;width:30%',
 *                 textStyle:  'padding:2px'
 *             },
 *             {
 *                 labelCls:  'label-right',
 *                 textStyle: 'color:green'
 *             }
 *         ],
 *         renderers: {
 *             phoneNumber: function(value, name, data){
 *                 var areaCode = value.substr(0, 3),
 *                     first = value.substr(3, 3),
 *                     last = value.substr(6);
 *                 // Formats number as "<b>(555)</b> 123-4567"
 *                 return Ext.String.format('<b>({0})</b> {1}-{2}', areaCode, first, last);
 *             }
 *         }
 *     };
 *
 *     // Example data
 *     var exampleData = {
 *         customer_id:  '8675309',
 *         customer_nm:  'Megacorp',
 *         phone_number: '5551234567'
 *     };
 *
 *     var panel = Ext.create('Ext.panel.Panel', {
 *         title: 'My Table',
 *         data:  exampleData,
 *         tpl:   Sms.util.TableGenerator.createTemplate(spec)
 *     });
 *
 */
Ext.define("Sms.util.TableGenerator", {
	singleton: true,

	/**
	 * @private
	 *
	 * Creates markup from the table layout spec and appends it to the buffer.
	 * @param {Object} spec The table layout spec
	 * @param {Array} buf The output buffer
	 * @return {Array} The passed buffer
	 */
	generateMarkup: function(spec, buf){
		var fields  = spec.fields,
			columns = spec.columns,

			colCount   = columns.length,
			fieldCount = fields.length,
			
			// TODO: This doesn't allow for much flexibility. If needed, add a
			// new "<row/altRow/table>Attrs" object and apply those properties
			// in the call to makeAttributes. Also might be nice to have a
			// "columnDefaults" object to apply to each column spec.
			// -Eric
			labelAttr  = [],
			textAttr   = [],
			rowAttr    = this.makeAttributes({
				"class": spec.rowCls,
				"style": spec.rowStyle
			}),
			altRowAttr = this.makeAttributes({
				"class": spec.altRowCls,
				"style": spec.altRowStyle
			}),
			tableAttr  = this.makeAttributes({
				"id":    spec.id || undefined,
				"class": spec.tableCls,
				"style": spec.tableStyle
			}),

			fieldIdx = 0,
			currField,
			currCol,
			currRow,
			cellColspan;

		// Since the column attributes will always be the same, pre-generate them.
		this.cacheColumnAttrs(columns, labelAttr, textAttr);

		buf.push('<table', tableAttr, '>');

		// Keep adding rows until we run out of fields.
		for(currRow = 0; fields[fieldIdx]; currRow++){
			buf.push('<tr', (currRow % 2) ? altRowAttr : rowAttr, '>');

			for(currCol = 0; currCol < colCount; currCol++){
				// TODO: Might be better to actually check if the field exists
				// and handle it properly instead of falling back to falsy-detection.
				// -Eric
				currField = fields[fieldIdx++] || {};
				buf.push('<td', labelAttr[currCol], '>', currField.label ? currField.label + ': ' : '&nbsp;', '</td>');

				// TODO: Include a "cellAttrs" property to fields like Table layout does?
				// -Eric
				buf.push('<td', textAttr[currCol]);

				// Make sure colspan value doesn't exceed number of remaining columns.
				// Don't include colspan property unless spanning 2 or more columns.
				cellColspan = Math.min(currField.colspan || 0, colCount - currCol);
				if(cellColspan > 1){
					// For each of our logical columns, we need to span 2 actual columns.
					// Minus 1 because we're not counting the label td in the first column.
					buf.push(' colspan="', (cellColspan * 2) - 1, '"');
					currCol += (cellColspan - 1);  // Subtract one because it will increment on loop
				}

				buf.push('>');
				
				// currField.renderer is just a string. The actual function is
				// applied in the createTemplate method.
				if(currField.name && currField.renderer){
					buf.push('{[this["', currField.renderer, '"](values["', currField.name, '"], "', currField.name, '", values, this)]}');
				}
				else{
					buf.push(currField.name ? '{' + currField.name + '}' : '&nbsp;');
				}
				buf.push('</td>');
			}

			buf.push('</tr>');
		}
		buf.push('</table>');

		return buf;
	},

	/**
	 * @private
	 *
	 * Pre-generates label and text cell attrributes from the column spec.
	 * @param {Array} cols The array of column configurations
	 * @param {Array} labelAttr The output array for label attributes
	 * @param {Array} textAttr The output array for text attributes
	 */
	cacheColumnAttrs: function(cols, labelAttr, textAttr){
		var tg = this;

		Ext.each(cols, function(col, idx){
			labelAttr[idx] = tg.makeAttributes({
				"class": col.labelCls,
				"style": col.labelStyle
			});
			textAttr[idx] = tg.makeAttributes({
				"class": col.textCls,
				"style": col.textStyle
			});
		});
	},

	/**
	 * @private
	 *
	 * Generates a string of HTML attributes from an object spec.
	 * @param {Object} attr The object of (attribute="value") pairs
	 * @return {String} The markup string
	 */
	makeAttributes: function(attributes){
		var buf = [''],
			str = Ext.String,
			prop, attr;

		for(prop in attributes){
			if(attributes.hasOwnProperty(prop) && attributes[prop]){
				attr = String(attributes[prop]);

				// If the property is style, make sure it ends with a semicolon
				if(prop === "style" && attr.slice(-1) !== ";"){
					attr += ";";
				}
				buf.push(prop + '="' + str.htmlEncode(attr) + '"');
			}
		}

		return buf.join(' ');
	},

	/**
	 * Returns the markup for the passed table spec.
	 * @param {Object} spec The table layout spec
	 * @return {String} The table HTML
	 */
	markup: function(spec){
		var buf = this.generateMarkup(spec, []);
		return buf.join('');
	},

	/**
	 * Creates a new Ext.XTemplate from the table spec.
	 * @param {Object} spec The table layout spec
	 * @return {Ext.XTemplate} The new template
	 */
	createTemplate: function(spec){
		var tpl = this.generateMarkup(spec, []),
			propObj = {disableFormats: true};

		if(spec.renderers){
			Ext.apply(propObj, spec.renderers);
		}

		tpl.push(propObj);
		return new Ext.XTemplate(tpl);
	}
});