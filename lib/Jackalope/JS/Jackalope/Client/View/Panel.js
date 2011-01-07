if (Jackalope             == undefined) var Jackalope             = function () {}
if (Jackalope.Client      == undefined)     Jackalope.Client      = function () {}
if (Jackalope.Client.View == undefined)     Jackalope.Client.View = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client View Panel
// ----------------------------------------------------------------------------

Jackalope.Client.View.Panel = function ( opts ) {
    this.element  = opts["element"]
    this.bindings = opts["bindings"];

    var self = this;
    this.$element = function () { return jQuery( this.element ) };

    if ( opts["data_source"] != undefined ) {
        this.set_data_source( opts["data_source"] );
    }
};

Jackalope.Client.View.Panel.prototype = new Jackalope.Client.Observable ();

Jackalope.Client.View.Panel.prototype.get_data_source = function () {
    return this.data_source;
};

Jackalope.Client.View.Panel.prototype.set_data_source = function ( data_source ) {
    this.data_source = data_source;
    for (var i = 0; i < this.bindings.length; i++) {
        this.bindings[i].set_target( this.data_source );
    }
    this.trigger('update:data_source', this);
};

Jackalope.Client.View.Panel.prototype.clear_data_source = function () {
    this.data_source = undefined;
    for (var i = 0; i < this.bindings.length; i++) {
        this.bindings[i].clear_target();
    }
    this.trigger('clear:data_source', this);
};

Jackalope.Client.View.Panel.prototype.show = function () {
    this.$element().show()
};
Jackalope.Client.View.Panel.prototype.hide = function () {
    this.$element().hide()
};