if (Jackalope == undefined) var Jackalope = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client
// ----------------------------------------------------------------------------

Jackalope.Client = function () {};

Jackalope.Client.Error = function (msg, reason) {
    this.name    = "Jackalope Error";
    this.message = msg;
    this.reason  = reason || msg;
}

Jackalope.Client.Error.prototype = {
    toString : function () { return this.message }
};

// ----------------------------------------------------------------------------
// Jackalope Client Event base class
// ----------------------------------------------------------------------------

Jackalope.Client.Eventful = function () {}

Jackalope.Client.Eventful.prototype = {
    // event binding ...
    "bind" : function( event_name, callback ) {
        if ( this._callbacks == undefined ) this._callbacks = {};
        if ( this._callbacks[ event_name ] == undefined ) {
            this._callbacks[ event_name ] = [];
        }
        this._callbacks[ event_name ].push( callback );
        return this;
    },
    // event triggering
    "trigger" : function( event_name, args ) {
        if ( this._callbacks == undefined ) this._callbacks = {};
        if ( this._callbacks[ event_name ] != undefined ) {
            var callbacks = this._callbacks[ event_name ];
            for ( var i = 0; i < callbacks.length; i++ ) {
                callbacks[i].apply( this, Array.prototype.slice.call( arguments, 1 ) );
            }
        }
        return this;
    }
};

// ----------------------------------------------------------------------------
// Jackalope Client Resource
// ----------------------------------------------------------------------------

Jackalope.Client.Resource = function (opts) { this.init( opts ) };

Jackalope.Client.Resource.prototype = new Jackalope.Client.Eventful ();
Jackalope.Client.Resource.prototype.init = function ( opts ) {
    if (opts            == undefined) return;
    if (opts["id"]      == undefined) throw new Jackalope.Error ("'id' is required");
    if (opts["body"]    == undefined) throw new Jackalope.Error ("'body' is required");
    if (opts["version"] == undefined) throw new Jackalope.Error ("'version' is required");
    if (opts["links"]   == undefined) throw new Jackalope.Error ("'links' are required");

    // public properties ...
    this.id      = opts["id"];
    this.version = opts["version"];
    this.links   = opts["links"];

    // internal properties ...
    this._body   = opts["body"];
};

Jackalope.Client.Resource.prototype.associate_schema = function ( schema, schema_repository ) {
    if (schema            == undefined) throw new Jackalope.Error ("You must supply a schema");
    if (schema_repository == undefined) throw new Jackalope.Error ("You must supply a schema repository instance");
    this.schema            = schema;
    this.schema_repository = schema_repository;
};
Jackalope.Client.Resource.prototype.has_associated_schema = function () {
    return this.schema != undefined && this.schema_repository != undefined;
};

Jackalope.Client.Resource.prototype.get = function ( name ) {
    return this._traverse_path_and_get( name, this._body );
};

Jackalope.Client.Resource.prototype.set = function ( attrs, options ) {
    if (Jackalope.Util.Object.key_count(attrs) == 0) return this;
    if (options == undefined) options = {};
    for (var k in attrs) {
        if ( this.has_associated_schema() ) {
            this._traverse_path_and_check_schema( k, attrs[ k ] );
        }
        this._traverse_path_and_set(
            k,
            this._body,
            attrs[ k ]
        );
        if (!options.silent) {
            this.trigger( 'update:' + k, this, attrs[ k ] );
        }
    }
    if (!options.silent) {
        this.trigger('update', this, attrs);
    }
    return this;
};

Jackalope.Client.Resource.prototype._traverse_path_and_check_schema = function ( path, value ) {
    var prop_schema;
    if ( path.indexOf('.') == -1 ) {
        if ( this.schema.properties[ path ] == undefined ) {
            if ( this.schema.additional_properties == undefined || this.schema.additional_properties[ path ] == undefined ) {
                throw new Jackalope.Client.Error ("The property (" + path + ") is not a valid property for this resource");
            }
            else {
                prop_schema = this.schema.additional_properties[ path ];
            }
        }
        else {
            prop_schema = this.schema.properties[ path ];
        }
    }
    else {
        var traverse_schema_props = function ( path, schema ) {
            if ( schema.type != 'object' ) return;
            var part = path.splice( 0, 1 );
            var found;
            if ( schema.properties == undefined || schema.properties[ part ] == undefined ) {
                if ( schema.additional_properties == undefined || schema.additional_properties[ part ] == undefined ) return;
                found = schema.additional_properties[ part ];
            }
            else {
                found = schema.properties[ part ];
            }
            return path.length == 0
                ? found
                : traverse_schema_props( path, found );
        };
        prop_schema = traverse_schema_props( path.split('.'), this.schema );
        if ( prop_schema == undefined ) {
            throw new Jackalope.Client.Error ("The property (" + path + ") is not a valid property for this resource");
        }
    }

    var result = this.schema_repository.validate( prop_schema, value );
    if (result.error) {
        throw new Jackalope.Client.Error ("The property (" + path + ") failed to validate", result.error);
    }
}

Jackalope.Client.Resource.prototype._traverse_path_and_get = function ( path, data ) {
    var parts   = path.split('.');
    var current = data;
    for (var i = 0; i < parts.length; i++) {
        current = current[ parts[i] ];
        if ( current == undefined ) return current;
    }
    return current;
};

Jackalope.Client.Resource.prototype._traverse_path_and_set = function ( path, data, value ) {
    var parts   = path.split('.');
    var final   = parts.pop();
    var current = data;
    for (var i = 0; i < parts.length; i++) {
        if ( current[ parts[i] ] == undefined && i < parts.length ) {
            // auto-vivify
            current[ parts[i] ] = {};
        }
        current = current[ parts[i] ];
    }
    current[ final ] = value;
};


// ----------------------------------------------------------------------------
// Jackalope Client Resource Collection
// ----------------------------------------------------------------------------

Jackalope.Client.Resource.Collection = function ( opts ) { this.init( opts ) }

Jackalope.Client.Resource.Collection.prototype = new Jackalope.Client.Eventful ();
Jackalope.Client.Resource.Collection.prototype.init = function ( opts ) {
    if (opts == undefined) return;
    // ...
}

Jackalope.Client.Resource.Collection.prototype.add = function ( resource ) {
    // ...
    this.trigger("add", this, resource );
};

Jackalope.Client.Resource.Collection.prototype.remove = function ( resource ) {
    // ...
    this.trigger("remove", this, resource );
};

Jackalope.Client.Resource.Collection.prototype.get = function ( index ) {
    // ...
};

Jackalope.Client.Resource.Collection.prototype.set = function ( index, resource ) {
    // ...
    this.trigger("update", this, index, resource );
};

// ----------------------------------------------------------------------------
// Jackalope Client Resource Repository
// ----------------------------------------------------------------------------

Jackalope.Client.Resource.Repository = function ( opts ) { this.init( opts ) }

Jackalope.Client.Resource.Repository.prototype = {
    "init" : function ( opts ) {
        if (opts == undefined) return;
        // properties needed:
            // url to the collection
            // the schema being used
                // the schema repository (for validation)

        // this object knows how to do the CRUD on
        // the various resources, it also knows the
        // base URL of the collection.

        // The methods will always try to use the
        // links in a resource when it makes sense

        // the methods should perform validation
        // using the Schema repository whenever
        // it makes sense (mostly for 'save', but
        // also maybe 'create', 'fetch' and 'refresh'
        // but that might be overkill since the server
        // will have already done that)
    },
    // the error callback should be given
    // some kind of indicator as to the type
    // of error it is
    "list" : function ( options, success, error ) {
        // this will return a resource collection ....
    },
    "create" : function ( data, success, error ) {
        // this will create a new resource ....
    },
    "fetch" : function ( id, success, error ) {
        // this will guess at the URL, based on the ID
    },
    "save" : function ( resource, success, error ) {
        // this will post an update ...
    },
    "refresh" : function ( resource, success, error ) {
        // this will grab the latest from the server
        // update the details, and fire change events
        // on the body
    },
    "destroy" : function ( resource, success, error ) {
        // this will delete the resource ...
    }
};
