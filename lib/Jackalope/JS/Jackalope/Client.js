if (Jackalope == undefined) var Jackalope = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client
// ----------------------------------------------------------------------------

Jackalope.Client = function () {};

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

Jackalope.Client.Resource = function (opts) {
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

Jackalope.Client.Resource.prototype = new Jackalope.Client.Eventful ();

Jackalope.Client.Resource.prototype.get = function ( name ) {
    return this._body[name];
};

Jackalope.Client.Resource.prototype.set = function ( attrs, options ) {
    if (Jackalope.Util.Object.key_count(attrs) == 0) return this;
    if (options == undefined) options = {};
    for (var k in attrs) {
        this._body[ k ] = attrs[ k ];
        if (!options.silent) {
            this.trigger( 'update:' + k, this, attrs[ k ] );
        }
    }
    if (!options.silent) {
        this.trigger('update', this, attrs);
    }
    return this;
};

// ----------------------------------------------------------------------------
// Jackalope Client Resource
// ----------------------------------------------------------------------------

Jackalope.Client.Resource.Repository = function ( opts ) {
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
}

// Ponder making this object do events.
// It is quite possible that the events
// this will trigger will be enough, but
// it might make sense

// the error callback should be given
// some kind of indicator as to the type
// of error it is

Jackalope.Client.Resource.Repository.create = function ( data, success, error ) {
    // this will create a new resource ....
};

Jackalope.Client.Resource.Repository.fetch = function ( id, success, error ) {
    // this will guess at the URL, based on the ID
};

Jackalope.Client.Resource.Repository.save = function ( resource, success, error ) {
    // this will post an update ...
};

Jackalope.Client.Resource.Repository.refresh = function ( resource, success, error ) {
    // this will grab the latest from the server
    // update the details, and fire change events
    // on the body
};

Jackalope.Client.Resource.Repository.destroy = function ( resource, success, error ) {
    // this will delete the resource ...
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding
// ----------------------------------------------------------------------------

Jackalope.Client.Binding = function ( opts ) {
    if (opts["element"]  == undefined) throw new Jackalope.Error ("'element' is required");
    if (opts["resource"] == undefined) throw new Jackalope.Error ("'resource' is required");
    if (opts["property"] == undefined) throw new Jackalope.Error ("'property' is required");

    if (typeof opts["element"] == 'string') {
        // in this case, it is assumed you have
        // passed something suitable to being
        // passed into the jQuery constructor,
        // like a CSS selector or HTML string
        opts["element"] = jQuery( opts["element"] );
    }

    this.element  = opts["element"];
    this.resource = opts["resource"];
    this.property = opts["property"];

    this.initialize();
};

Jackalope.Client.Binding.prototype = {
    "initialize" : function () {
        var self = this;

        self.element.change(function () {
            var changes = {};
            changes[ self.property ] = self.element.val() ;
            self.resource.set( changes );
        });

        self.resource.bind("update:" + self.property, function (resource, value) {
            self.element.val( value );
        });

        // NOTE:
        // we need to be careful of recursion here
        // when we set the value in the update event.
        // In this case the value will be updated, but
        // the 'change' event is not fired. However
        // it might be possible for some elements to
        // behave differently, so beware.
        // - SL

        self.element.val( self.resource.get( self.property ) );
    }
};














