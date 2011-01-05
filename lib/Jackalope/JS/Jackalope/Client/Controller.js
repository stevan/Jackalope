if (Jackalope        == undefined) var Jackalope        = function () {}
if (Jackalope.Client == undefined)     Jackalope.Client = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client Controller
// ----------------------------------------------------------------------------
// The controller is also an eventful object, which means it can be used
// with a Binding and as a wrapper around a Resource.
// ----------------------------------------------------------------------------

Jackalope.Client.Controller = function ( opts ) { this.init( opts ) }

Jackalope.Client.Controller.prototype = new Jackalope.Client.Eventful ();
Jackalope.Client.Controller.prototype.init = function ( opts ) {
    if (opts == undefined) return;
    for ( var prop in opts ) {
        this[ prop ] = opts[ prop ]
    }
};

Jackalope.Client.Controller.prototype.get = function ( name ) {
    return this._traverse_path_and_get( name, this );
};

Jackalope.Client.Controller.prototype.set = function ( name, value ) {
    this._traverse_path_and_set( name, this, value );
    this.trigger('update:' + name, this, value);
};
