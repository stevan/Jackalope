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

// -----------------------------------------------------------------------------
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
    this.validator = opts["validator"] || Jackalope.Schema.Validator.Core;
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

Jackalope.Schema.Validator.Core = {
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
    }
};

//Math.round(instance) === instance

// ============================================================================



