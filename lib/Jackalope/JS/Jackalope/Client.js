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
    "trigger" : function( event_name ) {
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
// This object serves as a wrapper around an body and obsorbs all the other
// properties as well. It matches the resources we use on the server side.
// The only property that is treated special is the 'body', which has the
// get and set accessors.
//
// We also support deep get/set accessor behavior as well using dot separated
// paths to access them. This not only works for embedded objects, but also
// for embedded arrays as well.
//
// Additionally if a schema is associated with the resource, then upon set
// the schema for that specific property will checked against the schema.
//
// A special caveat for deep-accessors though, we do not try and find the
// embedded schema, instead we always check at the first level only, so a
// set on the key 'foo.bar.baz' will validate at the 'foo' level to make
// sure that the full embedded object is valid. This make sense even more
// when you look at addressing embedded arrays too, such as 'foo.1', etc.
// ----------------------------------------------------------------------------

Jackalope.Client.Resource = function (opts) { this.init( opts ) };

Jackalope.Client.Resource.prototype = new Jackalope.Client.Eventful ();
Jackalope.Client.Resource.prototype.init = function ( opts ) {
    this.id      = opts["id"];
    this.version = opts["version"];
    this.links   = opts["links"] || [];
    this.body    = opts['body']  || {};
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
    return this._traverse_path_and_get( name, this.body );
};

Jackalope.Client.Resource.prototype.set = function ( attrs, options ) {
    if (Jackalope.Util.Object.key_count(attrs) == 0) return this;
    if (options == undefined) options = {};
    for (var k in attrs) {
        if ( this.has_associated_schema() ) {
            this._check_schema( k, attrs[ k ] );
        }
        this._traverse_path_and_set( k, this.body, attrs[ k ], k );
        if (!options.silent) {
            this.trigger( 'update:' + k, this, attrs[ k ] );
        }
    }
    if (!options.silent) {
        this.trigger('update', this, attrs);
    }
    return this;
};

// private methods ...

Jackalope.Client.Resource.prototype._check_schema = function ( path, value ) {
    var orig_path = path;
    // if the path is a deep-path then
    // we only validate from the first
    // level down, which means we have to ...
    if ( path.indexOf('.') != -1 ) {
        var parts = path.split('.');
        // change path to reflect
        // the single level depth
        path = parts.shift();
        // and make a copy of that
        // item so that we can validate
        // it against the schema below
        var copy = this.body[ path ] == undefined ? {} : Jackalope.Util.clone( this.body[ path ] );
        this._traverse_path_and_set( parts.join('.'), copy, value, orig_path );
        value = copy;
    }
    // now find the schema ...
    var prop_schema;
    if ( this.schema.properties[ path ] == undefined ) {
        if ( this.schema.additional_properties == undefined || this.schema.additional_properties[ path ] == undefined ) {
            throw new Jackalope.Client.Error ("The property (" + orig_path + ") is not a valid property for this resource");
        }
        else {
            prop_schema = this.schema.additional_properties[ path ];
        }
    }
    else {
        prop_schema = this.schema.properties[ path ];
    }
    // and validate it
    var result = this.schema_repository.validate( prop_schema, value );
    if (result.error) {
        throw new Jackalope.Client.Error ("The property (" + orig_path + ") failed to validate", result.error);
    }
}

Jackalope.Client.Resource.prototype._traverse_path_and_get = function ( path, data ) {
    var parts   = path.split('.');
    var current = data;
    for (var i = 0; i < parts.length; i++) {
        current = current[ parts[i] ];
        // if there is nothing there,
        // then we might as well return
        // undefined, even if we are not
        // finished the traversal, the
        // result is the same
        if ( current == undefined ) return current;
    }
    return current;
};

Jackalope.Client.Resource.prototype._traverse_path_and_set = function ( path, data, value, orig_path ) {
    var parts   = path.split('.');
    var final   = parts.pop();
    var current = data;
    for (var i = 0; i < parts.length; i++) {
        if ( current[ parts[i] ] == undefined && i < parts.length ) {
            // auto-vivify when we
            // hit a dead-end, this
            // is most appropriate
            // for additional_properties
            current[ parts[i] ] = {};
        }
        else if ( typeof current[ parts[i] ] != 'object' && i < parts.length ) {
            // if we still have parts and
            // the current item is not an
            // object, they obviously the
            // path is not valid, so we
            // throw an error
            throw new Jackalope.Client.Error ("The property (" + orig_path + ") is not a valid property for this resource");
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
