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

