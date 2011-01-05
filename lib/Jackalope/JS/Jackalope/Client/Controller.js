if (Jackalope        == undefined) var Jackalope        = function () {}
if (Jackalope.Client == undefined)     Jackalope.Client = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client Controller
// ----------------------------------------------------------------------------
// The controller is also an eventful object, which means it can be used
// with a Binding and as a wrapper around a Resource.
// ----------------------------------------------------------------------------

Jackalope.Client.Controller = function ( opts ) {
    this.bind('update:context', this.setup);
    this.init( opts )
}

Jackalope.Client.Controller.prototype = new Jackalope.Client.Eventful ();

Jackalope.Client.Controller.prototype.init = function ( opts ) {
    if (opts == undefined) return;
    this.bindings = opts["bindings"] || [];
    if ( opts["context"] != undefined ) {
        this.set_context( opts["context"] );
    }
};

Jackalope.Client.Controller.prototype.setup = function () {
    for (var i = 0; i < this.bindings.length; i++) {
        this.bindings[i].set_target( this.get_context() );
    }
    this.trigger('update:bindings', this);
};

Jackalope.Client.Controller.prototype.set_context = function ( obj ) {
    this.context = obj;
    this.trigger('update:context', this);
};

Jackalope.Client.Controller.prototype.get_context = function () {
    return this.context;
};

// ----------------------------------------------------------------------------
// Jackalope Client Array Controller
// ----------------------------------------------------------------------------

Jackalope.Client.ArrayController = function ( opts ) { this.init( opts ) }

Jackalope.Client.ArrayController.prototype = new Jackalope.Client.Controller ();

Jackalope.Client.ArrayController.prototype.init = function ( opts ) {
    if (opts == undefined) return;
    this.bindings   = opts["bindings"] || [];
    this.collection = opts["collection"];
};

Jackalope.Client.ArrayController.prototype.get_collection = function () {
    return this.collection
};


