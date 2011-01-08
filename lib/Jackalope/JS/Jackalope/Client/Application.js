if (Jackalope        == undefined) var Jackalope        = function () {}
if (Jackalope.Client == undefined)     Jackalope.Client = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client Application
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

Jackalope.Client.Application = function ( opts ) { this.init( opts ) };

Jackalope.Client.Application.prototype = new Jackalope.Client.Observable ();

Jackalope.Client.Application.prototype.init = function ( opts ) {
    if ( opts                    == undefined ) return;
    if ( opts['nib']             == undefined ) throw new Jackalope.Error ("You must provide a 'nib'");
    if ( opts['first_responder'] == undefined ) throw new Jackalope.Error ("You must provide a 'first_responder'");

    this.first_responder = opts['first_responder'];
    this.nib             = opts['nib'];
    this.awake_from_nib  = opts['awake_from_nib'];
}

Jackalope.Client.Application.prototype.awaken = function () {
    if ( this.awake_from_nib == undefined ) return;
    this.awake_from_nib.apply( this.nib );
};

Jackalope.Client.Application.prototype.main = function () {
    this.awaken();
    this.nib[ this.first_responder ].main()
};

