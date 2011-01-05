if (Jackalope        == undefined) var Jackalope        = function () {}
if (Jackalope.Client == undefined)     Jackalope.Client = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client Controller
// ----------------------------------------------------------------------------
// The controller is also an eventful object, which means it can be used
// with a Binding and as a wrapper around a Resource.
// ----------------------------------------------------------------------------

Jackalope.Client.Controller = function ( opts ) { this.init( opts ) }

Jackalope.Client.Controller.prototype = {
    "init" : function ( opts ) {
        if (opts == undefined) opts = {};

        this.bindings = opts["bindings"] || [];

        if ( opts["context"] != undefined ) {
            this.set_context( opts["context"] );
        }
    },
    "setup" : function () {
        for (var i = 0; i < this.bindings.length; i++) {
            this.bindings[i].set_target( this.context );
        }
    },
    "set_context" : function ( obj ) {
        this.context = obj;
        this.setup();
    }
};
