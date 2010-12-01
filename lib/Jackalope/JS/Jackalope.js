
function Jackalope () {}

Jackalope.Validator = function (opts) {
    if (!opts) opts = {};
    this.validator = opts["validator"] || Jackalope.Validator.Core;
}
Jackalope.Validator.prototype = {
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

Jackalope.Validator.Core = {
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
};