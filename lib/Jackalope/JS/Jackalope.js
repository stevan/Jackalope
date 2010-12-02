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

        if (schema["less_than"]) {
            if (data >= schema["less_than"])
                return { "error" : data + " is not less than " + schema["less_than"] };
        }

        if (schema["less_than_or_equal_to"]) {
            if (data > schema["less_than_or_equal_to"])
                return { "error" : data + " is not less than or equal to " + schema["less_than_or_equal_to"] };
        }

        if (schema["greater_than"]) {
            if (data <= schema["greater_than"])
                return { "error" : data + " is not greater than " + schema["greater_than"] };
        }

        if (schema["greater_than_or_equal_to"]) {
            if (data < schema["greater_than_or_equal_to"])
                return { "error" : data + " is not greater than or equal to " + schema["greater_than_or_equal_to"] };
        }

        if (schema["enum"]) {
            if (schema["enum"].indexOf( data ) == -1)
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

        if (schema["min_length"]) {
            if (data.length < schema["min_length"])
                return { "error" : data + " is not the minimum length of " + schema["min_length"] };
        }

        if (schema["max_length"]) {
            if (data.length > schema["max_length"])
                return { "error" : data + " is not the maximum length of " + schema["max_length"] };
        }

        if (schema["pattern"]) {
            var regex = new RegExp (schema["pattern"]);
            if (!regex.test(data))
                return { "error" : data + " does not match the pattern " + schema["pattern"] };
        }

        if (schema["format"]) {
            if (this.formatters.indexOf(schema["format"]) == -1)
                return { "error" : schema["format"] + " is not a valid formatter " };
        }

        if (schema["enum"]) {
            if (schema["enum"].indexOf(data) == -1)
                return { "error" : data + " is not a in the enum " + schema["enum"] };
        }

        return { "pass" : true };
    },
    "array" : function ( schema, data ) {
        if (data == null)              return { "error" : "null is not an array"    };
        if (data.constructor != Array) return { "error" : data + " is not an array" };

        if (schema["min_items"]) {
            if (data.length < schema["min_items"])
                return { "error" : data + " does not have the minimum number of items " + schema["min_items"] };
        }

        if (schema["max_items"]) {
            if (data.length > schema["max_items"])
                return { "error" : data + " does not have the maximum number of items " + schema["max_items"] };
        }

        if (schema["is_unique"]) {
            if (jQuery.unique( data ).length != data.length)
                return { "error" : data + " is not a unique array" };
        }

        if (schema["items"]) {
            return { "error" : "items not implemented yet" };
        }

        return { "pass" : true };
    },
    "object" : function ( schema, data ) {
        if (data == null)               return { "error" : "null is not an object"    };
        if (data.constructor != Object) return { "error" : data + " is not an object" };

        if (schema["properties"]) {
            return { "error" : "properties not implemented yet" };
        }

        if (schema["additional_properties"]) {
            return { "error" : "additional_properties not implemented yet" };
        }

        if (schema["items"]) {
            return { "error" : "items not implemented yet" };
        }

        return { "pass" : true };
    },
    "schema" : function ( schema, data ) {
        return this.object( schema, data );
    }
};


// ============================================================================



