if (Jackalope        == undefined) var Jackalope        = function () {}
if (Jackalope.Client == undefined)     Jackalope.Client = function () {}

Jackalope.Client.Binding = function () {};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Action
// ----------------------------------------------------------------------------
// This will work for a number of form element, basically anything that
// responds to the 'change' event and whose value is set with val(), which
// should be input[type=text]
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.Action = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Action.prototype = {
    "init" : function ( opts ) {
        if (opts                  == undefined) return;
        if (opts["element"]       == undefined) throw new Jackalope.Error ("'element' is required");
        if (opts["event_type"]    == undefined) throw new Jackalope.Error ("'event_type' is required");
        if (opts["target_action"] == undefined) throw new Jackalope.Error ("'target_action' is required");

        this.element       = opts["element"];
        this.event_type    = opts["event_type"];
        this.target_action = opts["target_action"];
        this.target        = opts["target"];

        var self = this;
        this.$element       = function () { return jQuery( self.element ) };
        this._element_event = function (e) { self.call_target_action(e) };

        this.setup();
    },
    "setup" : function () {
        if ( this.target == undefined ) return;
        this.register_element_event();
    },
    // user facing functions
    "set_target" : function ( target ) {
        this.clear_target();
        this.target = target;
        this.setup();
    },
    "clear_target" : function () {
        this.unregister_element_event();
        this.target = undefined;
    },
    // element handlers
    "register_element_event" : function () {
        this.$element().bind( this.event_type, this._element_event );
    },
    "unregister_element_event" : function () {
        this.$element().unbind( this.event_type, this._element_event );
    },
    // target action caller
    "call_target_action" : function () {
        this.target[this.target_action].apply( this.target, arguments );
    }
};


// ----------------------------------------------------------------------------
// Jackalope Client Binding Outlet
// ----------------------------------------------------------------------------
// This will work for a number of form element, basically anything that
// responds to the 'change' event and whose value is set with val(), which
// should be input[type=text]
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.Outlet = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Outlet.prototype = {
    "init" : function ( opts ) {
        if (opts             == undefined) return;
        if (opts["element"]  == undefined) throw new Jackalope.Error ("'element' is required");
        if (opts["property"] == undefined) throw new Jackalope.Error ("'property' is required");

        this.element     = opts["element"];
        this.target      = opts["target"];
        this.property    = opts["property"];

        this.transformer = opts["transformer"];
        this.formatter   = opts["formatter"];

        // private attributes
        var self = this;
        this.$element       = function () { return jQuery( self.element ) };
        this._element_event = function () { self.update_target() };
        this._target_event  = function () { self.update_element.apply( self, arguments ) };

        this.setup();
    },
    "setup" : function () {
        if ( this.target == undefined ) return;
        this.register_all_events();
        this.refresh();
    },
    // user facing functions
    "set_target" : function ( target ) {
        this.clear_target();
        this.target = target;
        this.setup();
    },
    "clear_target" : function () {
        if ( this.target != undefined ) {
            this.unregister_all_events();
            this.target = undefined;
            this.set_element_value('');
        }
    },
    "refresh" : function () {
        this.update_element(
            this.target,
            this.get_target_value()
        );
    },
    // default events
    "update_target" : function () {
        var value = this.get_element_value();
        if ( this.transformer ) {
            value = this.transformer( value );
        }
        this.set_target_value( value );
    },
    "update_element" : function ( target, value ) {
        if ( this.formatter ) {
            value = this.formatter( value );
        }
        this.set_element_value( value );
    },
    // event registration
    "unregister_all_events" : function () {
        this.unregister_target_event();
        this.unregister_element_event();
    },
    "register_all_events" : function () {
        this.register_element_event();
        this.register_target_event();
    },
    // -------------------------------
    // methods to change in subclasses
    // -------------------------------
    // element handlers
    "register_element_event" : function () {
        this.$element().bind( 'change', this._element_event );
    },
    "unregister_element_event" : function () {
        this.$element().unbind( 'change', this._element_event );
    },
    "get_element_value" : function () {
        return this.$element().val();
    },
    "set_element_value" : function ( value ) {
        this.$element().val( value );
    },
    // target handlers
    "register_target_event" : function () {
        this.target.bind( "update:" + this.property, this._target_event );
    },
    "unregister_target_event" : function () {
        this.target.unbind( "update:" + this.property, this._target_event );
    },
    "get_target_value" : function () {
        return this.target.get( this.property );
    },
    "set_target_value" : function ( value ) {
        return this.target.set( this.property, value );
    },
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Label
// ----------------------------------------------------------------------------
// This will handle binding a one way binding to a label
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.Outlet.Label = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Outlet.Label.prototype = new Jackalope.Client.Binding.Outlet ();
Jackalope.Client.Binding.Outlet.Label.prototype.register_element_event = function () {}; // it cannot be edited
Jackalope.Client.Binding.Outlet.Label.prototype.get_element_value = function () {
    return this.$element().html();
};
Jackalope.Client.Binding.Outlet.Label.prototype.set_element_value = function ( value ) {
    this.$element().html(value);
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Checkbox
// ----------------------------------------------------------------------------
// This will handle binding a checkbox too a boolean value
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.Outlet.Checkbox = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Outlet.Checkbox.prototype = new Jackalope.Client.Binding.Outlet ();
Jackalope.Client.Binding.Outlet.Checkbox.prototype.get_element_value = function () {
    return this.$element().attr("checked");
};
Jackalope.Client.Binding.Outlet.Checkbox.prototype.set_element_value = function ( value ) {
    this.$element().attr("checked", value);
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Radio Group
// ----------------------------------------------------------------------------
// This will handle binding a value from a group of radio buttons
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.Outlet.RadioGroup = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Outlet.RadioGroup.prototype = new Jackalope.Client.Binding.Outlet ();
Jackalope.Client.Binding.Outlet.RadioGroup.prototype.get_element_value = function () {
    return this.$element().filter(":checked").attr("value");
};
Jackalope.Client.Binding.Outlet.RadioGroup.prototype.set_element_value = function ( value ) {
    this.$element().attr("checked", false);
    this.$element().filter('[value="' + value + '"]').attr("checked", true);
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Checkbox Group
// ----------------------------------------------------------------------------
// This will handle binding values to a group of checkboxes
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.Outlet.CheckboxGroup = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Outlet.CheckboxGroup.prototype = new Jackalope.Client.Binding.Outlet ();
Jackalope.Client.Binding.Outlet.CheckboxGroup.prototype.get_element_value = function () {
    var acc = [];
    this.$element().filter(":checked").map(
        function () { acc.push( $(this).attr("value") ) }
    );
    return acc;
};
Jackalope.Client.Binding.Outlet.CheckboxGroup.prototype.set_element_value = function ( values ) {
    this.$element().attr("checked", false);
    for (var i = 0; i < values.length; i++) {
        this.$element().filter('[value="' + values[i] + '"]').attr("checked", true);
    }
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Select Pulldown
// ----------------------------------------------------------------------------
// This will handle binding values in a select pulldown
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.Outlet.SelectPulldown = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Outlet.SelectPulldown.prototype = new Jackalope.Client.Binding.Outlet ();
Jackalope.Client.Binding.Outlet.SelectPulldown.prototype.get_element_value = function () {

};
Jackalope.Client.Binding.Outlet.SelectPulldown.prototype.set_element_value = function ( values ) {

};






