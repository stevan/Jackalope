/* ============================================================================
   ___  _______  _______  ___   _  _______  ___      _______  _______  _______
  |   ||   _   ||       ||   | | ||   _   ||   |    |       ||       ||       |
  |   ||  |_|  ||       ||   |_| ||  |_|  ||   |    |   _   ||    _  ||    ___|
  |   ||       ||       ||      _||       ||   |    |  | |  ||   |_| ||   |___
 _|   ||       ||      _||     |_ |       ||   |___ |  |_|  ||    ___||    ___|
|     ||   _   ||     |_ |    _  ||   _   ||       ||       ||   |    |   |___
|_____||__| |__||_______||___| |_||__| |__||_______||_______||___|    |_______|
============================================================================ */

function Jackalope () {}

// ----------------------------------------------------------------------------
// Jackalope Schema
// ----------------------------------------------------------------------------

Jackalope.Schema = function () {}

// ----------------------------------------------------------------------------
// Schema Repository
// ----------------------------------------------------------------------------

Jackalope.Schema.Repository = function () {}

// ----------------------------------------------------------------------------
// Validator
// ----------------------------------------------------------------------------

Jackalope.Schema.Validator = function (opts) {
    if (!opts) opts = {};
    this.validator = opts["validator"] || new Jackalope.Schema.Validator.Core ();
}
Jackalope.Schema.Validator.prototype = {
    "validate" : function (schema, data) {
        if ( schema["type"] == undefined )
            throw new Error ("invalid schema");
        if ( !this.has_validator_for( schema["type"] ) )
            throw new Error ("No validator for type: " + schema["type"]);
        return this.validator[ schema["type"] ]( schema, data );
    },
    "has_validator_for" : function (type) {
        return this.validator[ type ] != undefined;
    }
};

// ----------------------------------------------------------------------------
// Validator Core
// ----------------------------------------------------------------------------

Jackalope.Schema.Validator.Core = function () {
    this.formatters = [ "uri", "uri_template", "regex" ]
}
Jackalope.Schema.Validator.Core.prototype = {
    "any"  : function () { return { "pass" : true } },
    "null" : function ( schema, data ) {
        return data == null
            ? { "pass" : true }
            : { "error" : data + " is not null" }
    },
    "boolean" : function ( schema, data ) {
        return data != null && data.constructor == Boolean
            ? { "pass" : true }
            : { "error" : data + " is not a boolean" }
    },
    "number" : function ( schema, data ) {
        if (data == null)               return { "error" : "null is not a number"    };
        if (data.constructor != Number) return { "error" : data + " is not a number" };

        if (schema["less_than"] != undefined) {
            if (data >= schema["less_than"])
                return { "error" : data + " is not less than " + schema["less_than"] };
        }

        if (schema["less_than_or_equal_to"] != undefined) {
            if (data > schema["less_than_or_equal_to"])
                return { "error" : data + " is not less than or equal to " + schema["less_than_or_equal_to"] };
        }

        if (schema["greater_than"] != undefined) {
            if (data <= schema["greater_than"])
                return { "error" : data + " is not greater than " + schema["greater_than"] };
        }

        if (schema["greater_than_or_equal_to"] != undefined) {
            if (data < schema["greater_than_or_equal_to"])
                return { "error" : data + " is not greater than or equal to " + schema["greater_than_or_equal_to"] };
        }

        if (schema["enum"] != undefined) {
            if (!this.utilities.contains(schema["enum"], data ))
                return { "error" : data + " is not part of the (number) enum (" + schema["enum"].join() + ")" };
        }

        return { "pass" : true };
    },
    "integer" : function ( schema, data ) {
        if (Math.round(data) !== data) return { "error" : data + " seems to be a floating point number" };
        return this.number( schema, data );
    },
    "string" : function ( schema, data ) {
        if (data == null)               return { "error" : "null is not a string"    };
        if (data.constructor != String) return { "error" : data + " is not a string" };

        if (schema["min_length"] != undefined) {
            if (data.length < schema["min_length"])
                return { "error" : data + " is not the minimum length of " + schema["min_length"] };
        }

        if (schema["max_length"] != undefined) {
            if (data.length > schema["max_length"])
                return { "error" : data + " is not the maximum length of " + schema["max_length"] };
        }

        if (schema["pattern"] != undefined) {
            var regex = new RegExp (schema["pattern"]);
            if (!regex.test(data))
                return { "error" : data + " does not match the pattern " + schema["pattern"] };
        }

        if (schema["format"] != undefined) {
            if (!this.utilities.contains(this.formatters, schema["format"]))
                return { "error" : schema["format"] + " is not a valid formatter " };
        }

        if (schema["enum"] != undefined) {
            if (!this.utilities.contains(schema["enum"], data))
                return { "error" : data + " is not a in the enum " + schema["enum"] };
        }

        return { "pass" : true };
    },
    "array" : function ( schema, data ) {
        if (data == null)              return { "error" : "null is not an array"    };
        if (data.constructor != Array) return { "error" : data + " is not an array" };

        if (schema["min_items"] != undefined) {
            if (data.length < schema["min_items"])
                return { "error" : data + " does not have the minimum number of items " + schema["min_items"] };
        }

        if (schema["max_items"] != undefined) {
            if (data.length > schema["max_items"])
                return { "error" : data + " does not have the maximum number of items " + schema["max_items"] };
        }

        if (data.length == 0) return { "pass" : true };

        if (schema["is_unique"] != undefined) {
            if (data.length != 1) {
                if (this.utilities.uniq( data ).length != data.length)
                    return { "error" : data + " is not a unique array" };
            }
        }

        if (schema["items"] != undefined) {
            var item_schema = schema["items"];
            var errors = [];
            for (var i = 0; i < data.length; i++) {
                var result = this[ item_schema["type"] ]( item_schema, data[i] );
                if (result["error"]) {
                    errors.push( result );
                }
            }
            if (errors.length)
                return {
                    "error"      : data + " did not pass the items test",
                    "sub_errors" : errors
                };
        }

        return { "pass" : true };
    },
    "object" : function ( schema, data ) {
        if (data == null)               return { "error" : "null is not an object"    };
        if (data.constructor != Object) return { "error" : data + " is not an object" };

        if (schema["properties"] != undefined) {
            for (var prop_name in schema["properties"]) {
                if (data[prop_name] == undefined)
                    return { "error" : "property " + prop_name + " didn't exist in data" };

                var prop_data   = data[prop_name];
                var prop_schema = schema["properties"][prop_name];

                var result = this[ prop_schema["type"] ]( prop_schema, prop_data );
                if (result["error"])
                    return {
                        "error"      : "property " + prop_name + " didn't pass the schema for " + prop_schema["type"],
                        "sub_errors" : result
                    };
            }
        }

        if (schema["additional_properties"] != undefined) {
            for (var prop_name in schema["additional_properties"]) {
                if (data[prop_name] != undefined) {
                    var prop_data   = data[prop_name];
                    var prop_schema = schema["additional_properties"][prop_name];
                    var result = this[ prop_schema["type"] ]( prop_schema, prop_data );
                    if (result["error"])
                        return {
                            "error"      : "additional_property " + prop_name + " didn't pass the schema for " + prop_schema["type"],
                            "sub_errors" : result
                        };
                }
            }
        }

        if (schema["items"] != undefined) {
            var item_schema = schema["items"];
            var errors = [];
            for (var prop in data) {
                var result = this[ item_schema["type"] ]( item_schema, data[prop] );
                if (result["error"]) {
                    errors.push( result );
                }
            }
            if (errors.length)
                return {
                    "error"      : data + " did not pass the items test",
                    "sub_errors" : errors
                };
        }

        return { "pass" : true };
    },
    "schema" : function ( schema, data ) {
        return this.object( schema, data );
    },
    // utility methods
    "utilities" : {
        "uniq" : function (array) {
            var obj = {};
            for (var i = 0; i < array.length ; i++) {
                obj[ array[i] ] = 0;
            }
            var out = [];
            for (var x in obj) {
                out.push(x);
            }
            return out;
        },
        "contains" : function (array, obj) {
            for (var i = 0; i < array.length; i++) {
                if ( array[i] == obj ) {
                    return true;
                }
            }
            return false;
        }
    }

};


// ============================================================================



