/* -------------------------------------------------------------------------------------------------- */
/*           ,---._                                                                                   */
/*         .-- -.' \                            ,-.             ,--,                                  */
/*         |    |   :                       ,--/ /|           ,--.'|            ,-.----.              */
/*         :    ;   |                     ,--. :/ |           |  | :     ,---.  \    /  \             */
/*         :        |                     :  : ' /            :  : '    '   ,'\ |   :    |            */
/*         |    :   :  ,--.--.     ,---.  |  '  /    ,--.--.  |  ' |   /   /   ||   | .\ :   ,---.    */
/*         :          /       \   /     \ '  |  :   /       \ '  | |  .   ; ,. :.   : |: |  /     \   */
/*         |    ;   |.--.  .-. | /    / ' |  |   \ .--.  .-. ||  | :  '   | |: :|   |  \ : /    /  |  */
/*     ___ l          \__\/: . ..    ' /  '  : |. \ \__\/: . .'  : |__'   | .; :|   : .  |.    ' / |  */
/*   /    /\    J   : ," .--.; |'   ; :__ |  | ' \ \," .--.; ||  | '.'|   :    |:     |`-''   ;   /|  */
/*  /  ../  `..-    ,/  /  ,.  |'   | '.'|'  : |--'/  /  ,.  |;  :    ;\   \  / :   : :   '   |  / |  */
/*  \    \         ;;  :   .'   \   :    :;  |,'  ;  :   .'   \  ,   /  `----'  |   | :   |   :    |  */
/*   \    \      ,' |  ,     .-./\   \  / '--'    |  ,     .-./---`-'           `---'.|    \   \  /   */
/*    "---....--'    `--`---'     `----'           `--`---'                       `---`     `----'    */
/*                                                                                                    */
/* -------------------------------------------------------------------------------------------------- */

function Jackalope () {}

Jackalope.VERSION   = '0.01';
Jackalope.AUTHORITY = 'cpan:STEVAN';

// ----------------------------------------------------------------------------
// Jackalope Error
// ----------------------------------------------------------------------------

Jackalope.Error = function (msg) {
    this.name    = "Jackalope Error";
    this.message = msg;
}

Jackalope.Error.prototype = {
    toString : function () { return this.message }
};

// ----------------------------------------------------------------------------
// Jackalope Serializer
// ----------------------------------------------------------------------------

Jackalope.Serializer = function () {}

Jackalope.Serializer.JSON = function () {}
Jackalope.Serializer.JSON.prototype = {
    "serialize" : function ( obj ) {
        return JSON.stringify( obj );
    },
    "deserialize" : function ( json ) {
        return JSON.parse( json );
    }
}

// ----------------------------------------------------------------------------
// Jackalope Schema
// ----------------------------------------------------------------------------

Jackalope.Schema = function () {}

// ----------------------------------------------------------------------------
// Schema Spec
// ----------------------------------------------------------------------------

Jackalope.Schema.Spec = function (opts) {
    if (opts.spec_url  == undefined) throw new Jackalope.Error ("You must specify a spec_url");
    this.spec    = null;
    this.version = opts.version || parseFloat( Jackalope.VERSION );
    this.init( opts.spec_url );
}

Jackalope.Schema.Spec.prototype = {
    "init" : function ( spec_url ) {
        var self = this;
        Jackalope.Util.Web.ajax({
            "async"   : false,
            "url"     : spec_url,
            "error"   : function (xhr, status, error) {
                throw new Jackalope.Error ("Could not load spec JSON");
            },
            "success" : function (data) {
                var serializer = new Jackalope.Serializer.JSON ();
                try {
                    self.spec = serializer.deserialize(data);
                } catch (e) {
                    throw new Jackalope.Error ("Could not parse spec JSON");
                }
            }
        });
        if (self.spec.version > self.version) {
            throw new Jackalope.Error ("Remote Spec (" + self.spec.version  + ") is a later"
                                      + " version then is supported by this client (" + self.version + ")");
        }
    },
    "get_spec" : function () {
        return this.spec
    },
    "valid_types" : function () {
        return Jackalope.Util.Object.keys( this.spec.typemap );
    },
    "get_uri_for_type" : function (type) {
        return this.spec.typemap[type];
    }
}

// ----------------------------------------------------------------------------
// Schema Repository
// ----------------------------------------------------------------------------

Jackalope.Schema.Repository = function (opts) {
    if (opts.spec      == undefined) throw new Jackalope.Error ("You must specify a spec");
    if (opts.validator == undefined) throw new Jackalope.Error ("You must specify a validator");
    this.validator        = opts.validator;
    this.spec             = opts.spec;
    this.compiled_schemas = {};
    this.init();
}

Jackalope.Schema.Repository.prototype = {
    "init" : function () {
        this.compiled_schemas = this._compile_core_schemas();
    },
    // schema accessors
    "get_compiled_schema_by_uri" : function ( uri ) {
        var schema = this.compiled_schemas[ uri ];
        if (schema == undefined)
            throw new Jackalope.Error ("Could not find schema for " + uri);
        return schema.compiled;
    },
    "get_compiled_schema_for_type" : function ( type ) {
        var schema = this.compiled_schemas[ this.spec.get_uri_for_type( type ) ];
        if (schema == undefined)
            throw new Jackalope.Error ("Could not find schema for " + type);
        return schema.compiled;
    },
    "get_compiled_schema_by_ref" : function ( ref ) {
        if (!this._is_ref( ref ))
            throw new Jackalope.Error (ref + " is not a ref");
        var schema = this._resolve_ref( ref, this.compiled_schemas );
        if (schema == undefined)
            throw new Jackalope.Error ("Could not find schema for " + ref["$ref"]);
        return schema.compiled;
    },
    // ....
    "validate" : function ( schema, data ) {
        var compiled_schema = this._compile_schema( schema );
        this._validate_schema( compiled_schema.compiled );
        return this.validator.validate( compiled_schema.compiled, data );
    },
    "register_schema" : function ( schema ) {
        if (schema.id == undefined)
            throw new Jackalope.Error ("Can only register schemas which have an id");
        var compiled_schema = this._compile_schema( schema );
        this._validate_schema( compiled_schema.compiled );
        this._insert_compiled_schema( compiled_schema );
        return compiled_schema.compiled;
    },
    // utilities
    "_validate_schema" : function ( schema ) {
        var schema_type = schema.type;
        var result = this.validator.validate(
            this.get_compiled_schema_for_type( schema_type ),
            schema
        );
        if (result.error) {
            try{
                console.log( "result", result );
                console.log( "schema", schema );
                console.log( "meta-schema", this.compiled_schemas["schema/types/" + schema_type] );
            } catch (e) {}
            throw new Jackalope.Error ("Invalid Schema");
        }
    },
    "_insert_compiled_schema" : function ( schema ) {
        this.compiled_schemas[ schema.compiled.id ] = schema;
    },
    "_compile_schema" : function ( schema ) {
        if (this._is_ref( schema )) {
            schema = this._resolve_ref( schema, this.compiled_schemas );
            if (schema == undefined)
                throw new Jackalope.Error ("Could not find schema for " . schema["$ref"]);
        }

        if ( !this._is_schema_compiled( schema ) ) {
            schema = this._prepare_schema_for_compiling( schema );
            this._flatten_extends( schema, this.compiled_schemas );
            this._resolve_embedded_extends( schema, this.compiled_schemas );
            this._resolve_refs( schema, this.compiled_schemas );
            this._mark_as_compiled( schema, this.compiled_schemas );
        }

        return schema;
    },
    "_compile_core_schemas" : function () {
        var self       = this;
        var spec       = this.spec.get_spec();
        var schemas    = Jackalope.Util.Array.map(
            function (s) { return self._prepare_schema_for_compiling( s ) },
            Jackalope.Util.Object.values( spec.schema_map )
        );
        var schema_map = this._generate_schema_map( schemas );

        for (var i = 0; i < schemas.length; i++) {
            this._flatten_extends( schemas[i], schema_map );
        }

        for (var i = 0; i < schemas.length; i++) {
            this._resolve_embedded_extends( schemas[i], schema_map );
        }

        for (var i = 0; i < schemas.length; i++) {
            this._resolve_refs( schemas[i], schema_map );
        }

        for (var i = 0; i < schemas.length; i++) {
            this._mark_as_compiled( schemas[i], schema_map );
        }

        return schema_map;
    },
    "_prepare_schema_for_compiling" : function ( raw ) {
        var schema = {
            "raw"         : raw,
            "compiled"    : Jackalope.Util.clone( raw ),
            "is_compiled" : false
        };
        return schema;
    },
    "_mark_as_compiled" : function ( schema ) {
        schema.is_compiled = true;
    },
    "_is_schema_compiled" : function ( schema ) {
        return schema.is_compiled;
    },
    "_generate_schema_map" : function ( schemas ) {
        var map = {};
        for (var i = 0; i < schemas.length; i++) {
            map[ schemas[i].compiled.id ] = schemas[i];
        }
        return map;
    },
    // ....
    "_flatten_extends" : function ( schema, schema_map ) {
        var self = this;
        if ( schema.raw["extends"] != undefined && this._is_ref( schema.raw["extends"] )) {
            this._merge_schema(
                schema,
                this._resolve_ref( schema.raw["extends"], schema_map ),
                schema_map
            );
            schema.compiled.properties = this._merge_properties( "properties", schema, schema_map );
            schema.compiled.additional_properties = this._merge_properties( "additional_properties", schema, schema_map );
            delete schema.compiled["extends"];
        }
    },
    "_merge_schema" : function ( schema, super_schema, schema_map ) {
        for (var k in super_schema.raw) {
            if ( ! (k == "id" || k == "properties" || k == "additional_properties") ) {
                if ( schema.raw[ k ] == undefined ) {
                    schema.compiled[ k ] = Jackalope.Util.clone( super_schema.raw[ k ] );
                }
            }
        }
        if ( super_schema.raw["extends"] != undefined && this._is_ref( super_schema.raw["extends"] ) ) {
            this._merge_schema(
                schema,
                this._resolve_ref( super_schema.raw["extends"], schema_map ),
                schema_map
            );
        }
    },
    "_merge_properties" : function ( type, schema, schema_map ) {
        return Jackalope.Util.Object.merge(
            schema.raw[type] == undefined
                ? {}
                : Jackalope.Util.clone( schema.raw[type] ),
            schema.raw["extends"] == undefined
                ? {}
                : this._merge_properties(
                    type,
                    this._resolve_ref( schema.raw["extends"], schema_map ),
                    schema_map
                )
        );
    },
    "_resolve_refs" : function ( schema, schema_map ) {
        var self     = this;
        var traverse = function ( obj ) {
            for (var p in obj) {
                var v = obj[p];
                if (Jackalope.Util.is_object( v )) {
                    if (self._is_ref( v )) {
                        if (self._is_self_ref( v )) {
                            obj[p] = schema.compiled;
                        }
                        else {
                            var s = self._resolve_ref( v, schema_map );
                            if (s == undefined)
                                throw new Jackalope.Error ("Could not find schema for " + v["$ref"]);
                            obj[p] = s.compiled;
                        }
                    }
                    else {
                        traverse( v );
                    }
                }
                else if (Jackalope.Util.is_array( v )) {
                    for (var i in v) {
                        traverse( v[i] );
                    }
                }
            }
        };
        traverse(schema.compiled);
    },
    "_resolve_embedded_extends" : function ( schema, schema_map ) {
        var self = this;
        var traverse = function ( obj ) {
            for (var p in obj) {
                var v = obj[p];
                if (Jackalope.Util.is_object( v )) {
                    if ( v["extends"] != undefined && self._is_ref( v["extends"] ) ) {
                        var embedded_schema = self._prepare_schema_for_compiling( v );
                        var new_schema_map = Jackalope.Util.Object.merge( { '#' : schema }, schema_map );
                        self._merge_schema(
                            embedded_schema,
                            self._resolve_ref( v["extends"], new_schema_map ),
                            new_schema_map
                        );
                        embedded_schema.compiled.properties = self._merge_properties( "properties", embedded_schema, new_schema_map );
                        embedded_schema.compiled.additional_properties = self._merge_properties( "additional_properties", embedded_schema, new_schema_map );
                        delete embedded_schema.compiled["extends"];
                        obj[p] = embedded_schema.compiled;
                    }
                    else {
                        traverse( v );
                    }
                }
                else if (Jackalope.Util.is_array( v )) {
                    for (var i in v) {
                        traverse( v[i] );
                    }
                }
            }
        };
        traverse(schema.compiled);
    },
    // Ref utils
    "_resolve_ref" : function ( ref, schema_map ) {
        return schema_map[ ref['$ref'] ];
    },
    "_is_ref" : function ( ref ) {
        return ref["$ref"] != undefined
            && Jackalope.Util.Object.key_count( ref ) == 1
            && typeof ref["$ref"] == "string";
    },
    "_is_self_ref" : function ( ref ) {
        return this._is_ref( ref ) && ref["$ref"] == "#";
    }
};

// ----------------------------------------------------------------------------
// Validator
// ----------------------------------------------------------------------------

Jackalope.Schema.Validator = function (opts) {
    if (!opts) opts = {};
    this.validator = opts.validator || new Jackalope.Schema.Validator.Core ();
}
Jackalope.Schema.Validator.prototype = {
    "validate" : function (schema, data) {
        if ( schema.type == undefined )
            throw new Jackalope.Error ("invalid schema");
        if ( !this.has_validator_for( schema.type ) )
            throw new Jackalope.Error ("No validator for type: " + schema.type);
        return this.validator[ schema.type ]( schema, data );
    },
    "has_validator_for" : function (type) {
        return this.validator[ type ] != undefined;
    }
};

// ----------------------------------------------------------------------------
// Validator Core
// ----------------------------------------------------------------------------

Jackalope.Schema.Validator.Core = function () {
    this.formatters = [ "uri", "uri_template", "regex", "uuid", "digest" ]
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

        if (schema.less_than != undefined) {
            if (data >= schema.less_than)
                return { "error" : data + " is not less than " + schema.less_than };
        }

        if (schema.less_than_or_equal_to != undefined) {
            if (data > schema.less_than_or_equal_to)
                return { "error" : data + " is not less than or equal to " + schema.less_than_or_equal_to };
        }

        if (schema.greater_than != undefined) {
            if (data <= schema.greater_than)
                return { "error" : data + " is not greater than " + schema.greater_than };
        }

        if (schema.greater_than_or_equal_to != undefined) {
            if (data < schema.greater_than_or_equal_to)
                return { "error" : data + " is not greater than or equal to " + schema.greater_than_or_equal_to };
        }

        if (schema["enum"] != undefined) {
            if (!Jackalope.Util.Array.contains(schema["enum"], data ))
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

        if (schema.literal != undefined) {
            if (data != schema.literal)
                return { "error" : data + " must exactly match " + schema.literal };
        }

        if (schema.min_length != undefined) {
            if (data.length < schema.min_length)
                return { "error" : data + " is not the minimum length of " + schema.min_length };
        }

        if (schema.max_length != undefined) {
            if (data.length > schema.max_length)
                return { "error" : data + " is not the maximum length of " + schema.max_length };
        }

        if (schema.pattern != undefined) {
            var regex = new RegExp (schema.pattern);
            if (!regex.test(data))
                return { "error" : data + " does not match the pattern " + schema.pattern };
        }

        if (schema.format != undefined) {
            if (!Jackalope.Util.Array.contains(this.formatters, schema.format))
                return { "error" : schema.format + " is not a valid formatter " };
        }

        if (schema["enum"] != undefined) {
            if (!Jackalope.Util.Array.contains(schema["enum"], data))
                return { "error" : data + " is not a in the enum " + schema["enum"] };
        }

        return { "pass" : true };
    },
    "array" : function ( schema, data ) {
        if (data == null)              return { "error" : "null is not an array"    };
        if (data.constructor != Array) return { "error" : data + " is not an array" };

        if (schema.min_items != undefined) {
            if (data.length < schema.min_items)
                return { "error" : data + " does not have the minimum number of items " + schema.min_items };
        }

        if (schema.max_items != undefined) {
            if (data.length > schema.max_items)
                return { "error" : data + " does not have the maximum number of items " + schema.max_items };
        }

        if (data.length == 0) return { "pass" : true };

        if (schema.is_unique != undefined) {
            if (data.length != 1) {
                if (Jackalope.Util.Array.uniq( data ).length != data.length)
                    return { "error" : data + " is not a unique array" };
            }
        }

        if (schema.items != undefined) {
            var item_schema = schema.items;
            var errors = [];
            for (var i = 0; i < data.length; i++) {
                var result = this[ item_schema.type ]( item_schema, data[i] );
                if (result.error) {
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

        var all_props = {};
        for (var prop in data) {
            all_props[ prop ] = 1;
        }

        var has_properties            = Jackalope.Util.Object.key_count(schema.properties) != 0;
        var has_additional_properties = Jackalope.Util.Object.key_count(schema.additional_properties) != 0;

        if (has_properties) {
            for (var prop_name in schema.properties) {
                if (data[prop_name] == undefined)
                    return { "error" : "property " + prop_name + " didn't exist in data" };

                var prop_data   = data[prop_name];
                var prop_schema = schema.properties[prop_name];

                if (this[ prop_schema.type ] == undefined)
                    return { "error" : "couldnt find validator for " + prop_schema.type + " for property " + prop_name };

                var result = this[ prop_schema.type ]( prop_schema, prop_data );
                if (result.error)
                    return {
                        "error"      : "property " + prop_name + " didn't pass the schema for " + prop_schema.type,
                        "sub_errors" : result
                    };

                delete all_props[ prop_name ];
            }
        }

        if (has_additional_properties) {
            for (var prop_name in schema.additional_properties) {
                if (data[prop_name] != undefined) {
                    var prop_data   = data[prop_name];
                    var prop_schema = schema.additional_properties[prop_name];

                    if (this[ prop_schema.type ] == undefined)
                        return { "error" : "couldnt find validator for " + prop_schema.type + " for additional-property " + prop_name };

                    var result = this[ prop_schema.type ]( prop_schema, prop_data );
                    if (result.error)
                        return {
                            "error"      : "additional-property " + prop_name + " didn't pass the schema for " + prop_schema.type,
                            "sub_errors" : result
                        };
                }
                delete all_props[ prop_name ];
            }
        }

        if (has_properties || has_additional_properties) {
            if (Jackalope.Util.Object.key_count( all_props ) != 0)
                return {
                    "error"           : data + " did not match all the expected properties",
                    "remaining_props" : all_props,
                    "schema"          : schema
                };
        }

        if (schema.items != undefined) {
            var item_schema = schema.items;
            var errors = [];
            for (var prop in data) {
                var result = this[ item_schema.type ]( item_schema, data[prop] );
                if (result.error) {
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
};

// ----------------------------------------------------------------------------
// Utilities
// ----------------------------------------------------------------------------

Jackalope.Util = {
    "clone" : function ( x ) {
        if (jQuery.isArray(x)) {
            return jQuery.merge( [], x );
        } else if (jQuery.isPlainObject(x)) {
            return jQuery.extend(true, {}, x);
        } else {
            return x;
        }
    },
    "is_object" : function ( x ) {
        return jQuery.isPlainObject(x);
    },
    "is_array" : function ( x ) {
        return jQuery.isArray(x);
    },
    "Web" : {
        "ajax" : function (opts) {
            jQuery.ajax( opts )
        }
    },
    "Array" : {
        "uniq" : function (array) {
            var r = [];
            o : for (var i = 0, n = array.length; i < n; i++) {
                for (var x = 0, y = r.length; x < y; x++) {
                    if(r[x] == array[i]) {
                        continue o;
                    }
                }
                r[r.length] = array[i];
            }
            return r;
        },
        "contains" : function (array, obj) {
            for (var i = 0; i < array.length; i++) {
                if ( array[i] == obj ) {
                    return true;
                }
            }
            return false;
        },
        "map" : function ( f, array ) {
            return jQuery.map( array, f );
        }
    },
    "Object" : {
        "keys" : function ( obj ) {
            var acc = [];
            for (var p in obj) { acc.push( p ) }
            return acc;
        },
        "values" : function ( obj ) {
            var acc = [];
            for (var p in obj) { acc.push( obj[p] ) }
            return acc;
        },
        "key_count" : function ( obj ) {
            var count = 0;
            for (var p in obj) { count++ }
            return count;
        },
        "merge" : function ( o1, o2 ) {
            var o3 = {};
            for (var p in o2) { o3[p] = o2[p] }
            for (var p in o1) { o3[p] = o1[p] }
            return o3;
        }
    }
};

// ============================================================================


