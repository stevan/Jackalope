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
// Schema Spec
// ----------------------------------------------------------------------------

Jackalope.Schema.Spec = function (opts) {
    if (opts["spec_url"]  == undefined) throw new Error ("You must specify a spec_url");
    this.spec_url = opts["spec_url"];
}

Jackalope.Schema.Spec.prototype = {
    "get_all_schemas" : function ( spec_url ) {
        var schemas;
        jQuery.ajax({
            "async"   : false,
            "url"     : this.spec_url,
            "error"   : function (xhr, status, error) {
                throw new Error ("Could not load spec JSON");
            },
            "success" : function (data) {
                try {
                    schemas = JSON.parse(data);
                } catch (e) {
                    throw new Error ("Could not parse spec JSON");
                }
            }
        });
        return schemas;
    }
}

// ----------------------------------------------------------------------------
// Schema Repository
// ----------------------------------------------------------------------------

Jackalope.Schema.Repository = function (opts) {
    if (opts["spec"]      == undefined) throw new Error ("You must specify a spec");
    if (opts["validator"] == undefined) throw new Error ("You must specify a validator");
    this.validator        = opts["validator"];
    this.spec             = opts["spec"];
    this.compiled_schemas = {};
    this.init();
}

Jackalope.Schema.Repository.prototype = {
    "init" : function () {
        var schemas = this.spec.get_all_schemas();

        var schema_map = {};
        for (var i = 0; i < schemas.length; i++) {
            schema_map[ schemas[i]["id"] ] = schemas[i];
        }

        for (var i = 0; i < schemas.length; i++) {
            schema_map[ schemas[i]["id"] ] = this._flatten_extends( schemas[i], schema_map );
        }

        for (var i = 0; i < schemas.length; i++) {
            schema_map[ schemas[i]["id"] ] = this._resolve_refs( schemas[i], schema_map );
        }

        for (var id in schema_map) {
            var schema = schema_map[id];
            if (schema["$ref"] != undefined) {
                delete schema["$ref"]
            }
        }

        this.compiled_schemas = schema_map;
    },
    "validate" : function ( schema, data ) {
        schema = this._compile_schema( schema );
        this._validate_schema( schema );
        return this.validator.validate( schema, data );
    },
    // utilities
    "_validate_schema" : function ( schema ) {
        var schema_type = schema["type"];
        var result = this.validator.validate(
            this.compiled_schemas["schema/types/" + schema_type],
            schema
        );
        if (result["error"]) {
            throw new Error ("Invalid Schema");
            try{
                console.log( "result", result );
                console.log( "schema", schema );
                console.log( "meta-schema", this.compiled_schemas["schema/types/" + schema_type] );
            } catch (e) {}
        }
    },
    "_compile_schema" : function ( schema ) {
        if (this._is_ref( schema )) {
            schema = this.compiled_schemas[ schema["$ref"] ];
        }

        if (schema["__compiled_properties"] == undefined && schema["__compiled_additional_properties"] == undefined) {
            schema = this._flatten_extends( schema, this.compiled_schemas );
            schema = this._resolve_refs( schema, this.compiled_schemas );
        }

        return schema;
    },
    "_resolve_refs" : function ( schema, schema_map ) {
        var self = this;
        return self._object_traverse(
            schema,
            function (v) {
                if (typeof v == "object" && self._is_ref( v )) {
                    if (self._is_self_ref( v )) {
                        return schema;
                    }
                    else {
                        return schema_map[ v["$ref"] ];
                    }
                }
                return v;
            }
        );
    },
    "_flatten_extends" : function ( schema, schema_map ) {
        var self = this;
        // NOTE:
        // the root schemas always need
        // these, no matter what
        // - SL
        schema["__compiled_properties"]            = schema["properties"] || {};
        schema["__compiled_additional_properties"] = schema["additional_properties"] || {};
        return self._object_traverse(
            schema,
            function (v) {
                if (typeof v == "object" && v["extends"] != undefined && self._is_ref( v["extends"] )) {
                    //console.log(">>>> Found extends and it was a ref");
                    return self._compile_properties( v, schema_map );
                }
                return v;
            }
        );
    },
    "_compile_properties" : function ( schema, schema_map ) {
        //console.log("!!!! compiling properties ");
        //console.log(schema);
        schema["__compiled_properties"]            = this._merge_properties( "properties", schema, schema_map );
        schema["__compiled_additional_properties"] = this._merge_properties( "additional_properties", schema, schema_map );
        //console.log(schema);
        return schema;
    },
    "_merge_properties" : function ( type, schema, schema_map ) {
        //console.log("...... merging properties");
        return this._object_merge(
            schema[type],
            schema["extends"] == undefined
                ? {}
                : this._merge_properties(
                    type,
                    schema_map[ schema["extends"]["$ref"] ],
                    schema_map
                )
        );
    },
    "_is_ref" : function ( ref ) {
        return ref["$ref"] != undefined
            && this._key_count( ref ) == 1
            && typeof ref["$ref"] == "string";
    },
    "_is_self_ref" : function ( ref ) {
        return this._is_ref( ref ) && ref["$ref"] == "#";
    },
    // primative utils
    "_key_count" : function ( obj ) {
        var count = 0;
        for (var p in obj) { count++ }
        return count;
    },
    "_object_merge" : function ( o1, o2 ) {
        var o3 = {};
        for (var p in o2) { o3[p] = o2[p] }
        for (var p in o1) { o3[p] = o1[p] }
        return o3;
    },
    "_object_traverse" : function ( obj, func, indent ) {
        indent = indent || "";
        var result = func( obj );
        for (var p in obj) {
            //console.log(indent + "visiting " + p + " in " + obj);
            if ( typeof obj[p] == "object" ) {
                result[p] = this._object_traverse( obj[p], func, indent + ".." );
            }
            else {
                result[p] = func( obj[p] );
            }
        }
        return result;
    }
};

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



