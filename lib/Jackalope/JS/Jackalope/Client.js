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
// Jackalope Client Observer Base class
// ----------------------------------------------------------------------------

Jackalope.Client.Observable = function () {}

Jackalope.Client.Observable.prototype = {
    // event binding ...
    "bind" : function( event_name, callback ) {
        if ( this._callbacks == undefined ) this._callbacks = {};
        if ( this._callbacks[ event_name ] == undefined ) {
            this._callbacks[ event_name ] = [];
        }
        this._callbacks[ event_name ].push( callback );
        return this;
    },
    "unbind" : function( event_name, callback ) {
        if ( this._callbacks               == undefined ) return;
        if ( this._callbacks[ event_name ] == undefined ) return;
        var callbacks = this._callbacks[ event_name ];
        for (var i = 0; i < callbacks.length; i++) {
            if (callbacks[i] === callback) {
                Jackalope.Util.Array.remove( callbacks, i );
            }
        }
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
// Jackalope Client Traverser Base class
// ----------------------------------------------------------------------------

Jackalope.Client.Traversable = function () {}

Jackalope.Client.Traversable.prototype = {
    "traverse_path_and_get" : function ( path, context ) {
        var parts   = path.split('.');
        var current = context;
        for (var i = 0; i < parts.length; i++) {
            var part = parts[i];
            if ( current[ part ] != undefined && current[ part ].constructor == Function ) {
                current = current[ part ].call( this );
            }
            else {
                current = current[ part ];
            }
            // if there is nothing there,
            // then we might as well return
            // undefined, even if we are not
            // finished the traversal, the
            // result is the same
            if ( current == undefined ) return current;
        }
        return current;
    },
    "traverse_path_and_set" : function ( path, context, value, full_path ) {
        if ( full_path == undefined ) full_path = path;
        var parts   = path.split('.');
        var final   = parts.pop();
        var current = context;
        for (var i = 0; i < parts.length; i++) {
            var part = parts[i];
            if ( current[ part ] != undefined && current[ part ].constructor == Function ) {
                current = current[ part ].call( this );
            }
            else {
                if ( current[ part ] == undefined && i < parts.length ) {
                    // auto-vivify when we
                    // hit a dead-end, this
                    // is most appropriate
                    // for additional_properties
                    current[ part ] = {};
                }
                else if ( typeof current[ part ] != 'object' && i < parts.length ) {
                    // if we still have parts and
                    // the current item is not an
                    // object, they obviously the
                    // path is not valid, so we
                    // throw an error
                    throw new Jackalope.Client.Error ("The property (" + full_path + ") is not a valid property");
                }
                current = current[ part ];
            }
        }
        // if we have reached the end
        // and we find a Function, then
        // we assume it is a setter can
        // so we call it
        if ( current[ final ] != undefined && current[ final ].constructor == Function ) {
            current[ final ].call( this, value );
        }
        else {
            current[ final ] = value;
        }
    }
};




