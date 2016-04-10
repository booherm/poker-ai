/**
 * JavaScript base64 utility.
 * Adapted from http://www.webtoolkit.info/javascript-base64.html
 */
Ext.define("Sms.Base64", {
	singleton: true,
	keyStr:    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

	/**
	 * Encodes a given input string into base64.
	 * @param {String} input The input string to encode.
	 * @param {Boolean} [toUtf8=false] `true` to encode as UTF-8
	 * @return {String} The base64-encoded string.
	 */
	encode: function(input, toUtf8){
		var output = "";
		var i      = 0;
		var keyStr = this.keyStr;
		var len, chr1, chr2, chr3, enc1, enc2, enc3, enc4;

		if(toUtf8){
			input = this.utf8Encode(input);
		}

		len = input.length;

		while(i < len){
			chr1 = input.charCodeAt(i++);
			chr2 = input.charCodeAt(i++);
			chr3 = input.charCodeAt(i++);

			enc1 = chr1 >> 2;
			enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
			enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
			enc4 = chr3 & 63;

			if(isNaN(chr2)){
				enc3 = enc4 = 64;
			} else if(isNaN(chr3)){
				enc4 = 64;
			}

			output += keyStr.charAt(enc1) + keyStr.charAt(enc2)
				+ keyStr.charAt(enc3) + keyStr.charAt(enc4);
		}

		return output;
	},

	/**
	 * Decodes a base64 string into normal text.
	 * @param {String} input The input string to decode.
	 * @param {Boolean} [fromUtf8=false] `true` to decode as UTF-8
	 * @return {String} The decoded string.
	 */
	decode: function(input, fromUtf8){
		input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

		var output = "";
		var i      = 0;
		var keyStr = this.keyStr;
		var len    = input.length;
		var chr1, chr2, chr3, enc1, enc2, enc3, enc4;

		while(i < len){
			enc1 = keyStr.indexOf(input.charAt(i++));
			enc2 = keyStr.indexOf(input.charAt(i++));
			enc3 = keyStr.indexOf(input.charAt(i++));
			enc4 = keyStr.indexOf(input.charAt(i++));

			chr1 = (enc1 << 2) | (enc2 >> 4);
			chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
			chr3 = ((enc3 & 3) << 6) | enc4;

			output += String.fromCharCode(chr1);
			if(enc3 != 64){
				output += String.fromCharCode(chr2);
			}
			if(enc4 != 64){
				output += String.fromCharCode(chr3);
			}
		}

		if(fromUtf8){
			output = this.utf8Decode(output);
		}

		return output;
	},

	/**
	 * Converts an input string into UTF-8.
	 * @param {String} str The string to convert.
	 * @return {String} The input string in UTF-8.
	 */
	utf8Encode: function(str){
		str = str.replace(/\r\n/g, "\n");

		var utftext = "";
		var len     = str.length;
		var i, c;

		for(i = 0; i < len; i++){
			c = str.charCodeAt(i);

			if(c < 128){
				utftext += String.fromCharCode(c);
			} else if((c > 127) && (c < 2048)){
				utftext += String.fromCharCode((c >> 6) | 192);
				utftext += String.fromCharCode((c & 63) | 128);
			} else{
				utftext += String.fromCharCode((c >> 12) | 224);
				utftext += String.fromCharCode(((c >> 6) & 63) | 128);
				utftext += String.fromCharCode((c & 63) | 128);
			}
		}

		return utftext;
	},

	/**
	 * Converts an input string from UTF-8.
	 * @param {String} str The string to convert.
	 * @return {String} The input string converted out of UTF-8.
	 */
	utf8Decode: function(utftext){
		var str = "";
		var i   = 0;
		var c1   = 0;
		var c2  = 0;
		var c3  = 0;
		var len = utftext.length;

		while(i < len){
			c1 = utftext.charCodeAt(i);

			if(c1 < 128){
				str += String.fromCharCode(c1);
				++i;
			} else if((c1 > 191) && (c1 < 224)){
				c2 = utftext.charCodeAt(i + 1);
				str += String.fromCharCode(((c1 & 31) << 6) | (c2 & 63));
				i += 2;
			} else{
				c2 = utftext.charCodeAt(i + 1);
				c3 = utftext.charCodeAt(i + 2);
				str += String.fromCharCode(((c1 & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
				i += 3;
			}
		}

		return str;
	}
});
