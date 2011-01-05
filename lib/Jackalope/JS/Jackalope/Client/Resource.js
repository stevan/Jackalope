if (Jackalope        == undefined) var Jackalope        = function () {}
if (Jackalope.Client == undefined)     Jackalope.Client = function () {}

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

Jackalope.Client.Resource.prototype.serialize = function ( serializer ) {
    return serializer.serialize({
        id      : this.id,
        version : this.version,
        body    : this.body
    });
}

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
    if (opts              == undefined) throw new Jackalope.Error ("Opts must be defined");
    if (opts["resources"] == undefined) throw new Jackalope.Error ("You must supply a set of resources");
    this.resources = opts["resources"];
}

Jackalope.Client.Resource.Collection.prototype.add = function ( resource ) {
    this.resources.push( resource );
    this.trigger("add", this, resource );
};

Jackalope.Client.Resource.Collection.prototype.remove = function ( resource ) {
    // ...
    this.trigger("remove", this, resource );
};

Jackalope.Client.Resource.Collection.prototype.get = function ( index ) {
    return this.resources[ index ];
};

Jackalope.Client.Resource.Collection.prototype.set = function ( index, resource ) {
    this.resources[ index ] = resource;
    this.trigger("update", this, index, resource );
};

// ----------------------------------------------------------------------------
// Jackalope Client Resource Repository
// ----------------------------------------------------------------------------
// You must create a repository for each schema you wish to handle.
// ----------------------------------------------------------------------------

Jackalope.Client.Resource.Repository = function ( opts ) { this.init( opts ) }

Jackalope.Client.Resource.Repository.prototype = {
    "init" : function ( opts ) {
        if (opts                      == undefined) throw new Jackalope.Error ("Opts must be defined");
        if (opts["base_url"]          == undefined) throw new Jackalope.Error ("You must supply a url for the resource repository");
        if (opts["schema"]            == undefined) throw new Jackalope.Error ("You must supply a schema for the resource repository");
        if (opts["schema_repository"] == undefined) throw new Jackalope.Error ("You must supply a schema repository for the resource repository");

        this.base_url          = opts["base_url"];
        this.schema            = opts["schema"];
        this.schema_repository = opts["schema_repository"];
        this.serializer        = new Jackalope.Serializer.JSON ();
    },
    "list" : function ( options, success, error ) {
        var self      = this;
        var hyperlink = this.schema.links.list;
        this._call_ajax({
            "url"     : this._build_url( hyperlink, {} ),
            "type"    : hyperlink.method,
            "data"    : options,
            "success" : function (data) {
                var resources = new Jackalope.Client.Resource.Collection ({
                    resources : Jackalope.Util.Array.map(
                        function ( d ) {
                            var resource = self._inflate_resource( d );
                            resource.associate_schema(
                                self.schema,
                                self.schema_repository
                            );
                            return resource;
                        },
                        self._inflate_data( data )
                    )
                });
                success( resources )
            },
            "error"   : error,
        });
    },
    "create" : function ( data, success, error ) {
        var hyperlink = this.schema.links.create;
        this._call_ajax({
            "url"     : this._build_url( hyperlink, {} ),
            "type"    : hyperlink.method,
            "data"    : this.serializer.serialize( data ),
            "success" : this._wrap_callback( success ),
            "error"   : error,
        });
    },
    "read" : function ( id, success, error ) {
        var hyperlink = this.schema.links.read;
        this._call_ajax({
            "url"     : this._build_url( hyperlink, { 'id' : id } ),
            "type"    : hyperlink.method,
            "success" : this._wrap_callback( success ),
            "error"   : error,
        })
    },
    "edit" : function ( resource, success, error ) {
        var hyperlink = this.schema.links.edit;
        this._call_ajax({
            "url"     : this._build_url( hyperlink, { 'id' : resource.id } ),
            "type"    : hyperlink.method,
            "data"    : resource.serialize( this.serializer ),
            "success" : this._wrap_callback( success ),
            "error"   : error,
        })
    },
    "destroy" : function ( resource, success, error ) {
        var hyperlink = this.schema.links['delete'];
        this._call_ajax({
            "url"     : this._build_url( hyperlink, { 'id' : resource.id } ),
            "type"    : hyperlink.method,
            "headers" : { 'If-Matches' : resource.version },
            "success" : success,
            "error"   : error,
        })
    },
    // private methods ...
    "_wrap_callback" : function ( callback ) {
        var self = this;
        return function ( data ) {
            var resource = self._inflate_resource( data );
            resource.associate_schema(
                self.schema,
                self.schema_repository
            );
            callback( resource )
        }
    },
    "_inflate_data" : function ( data ) {
        if (typeof data == 'string') {
            try {
                data = this.serializer.deserialize(data);
            } catch (e) {
                throw new Jackalope.Error ("Could not parse spec JSON");
            }
        }
        return data;
    },
    "_inflate_resource" : function ( data ) {
        return new Jackalope.Client.Resource( this._inflate_data( data ) );
    },
    "_call_ajax" : function ( opts ) {
        Jackalope.Util.Web.ajax( opts );
    },
    "_build_url" : function ( hyperlink, params ) {
        var url  = this.base_url;
        var href = hyperlink.href;
        for ( var param in params ) {
            href = href.replace( ':' + param, params[ param ] );
        }
        return url + href;
    }
};
