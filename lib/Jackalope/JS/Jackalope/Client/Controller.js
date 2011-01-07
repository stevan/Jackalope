if (Jackalope        == undefined) var Jackalope        = function () {}
if (Jackalope.Client == undefined)     Jackalope.Client = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client Controller
// ----------------------------------------------------------------------------
// The controller is also an eventful object, which means it can be used
// with a Binding and as a wrapper around a Resource.
//
// EVENTS:
// update:context  => fired when the context is set
//                    NOTE: we also bind the setup() method to this
// clear:context   => fired when the context is cleared
// ----------------------------------------------------------------------------

Jackalope.Client.Controller = function ( opts ) { this.init( opts ) }

Jackalope.Client.Controller.prototype = new Jackalope.Client.Observable ();

Jackalope.Client.Controller.prototype.init = function ( opts ) {
    if (opts == undefined) return;
    if ( opts["context"] != undefined ) {
        this.set_context( opts["context"] );
    }
};

Jackalope.Client.Controller.prototype.set_context = function ( context ) {
    this.context = context;
    this.trigger('update:context', this, context);
};

Jackalope.Client.Controller.prototype.get_context = function () {
    return this.context;
};

Jackalope.Client.Controller.prototype.has_context = function () {
    return this.context != undefined;
};

Jackalope.Client.Controller.prototype.clear_context = function () {
    this.context = undefined;
    this.trigger('clear:context', this);
};


