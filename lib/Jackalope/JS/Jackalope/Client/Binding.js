if (Jackalope        == undefined) var Jackalope        = function () {}
if (Jackalope.Client == undefined)     Jackalope.Client = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client Binding
// ----------------------------------------------------------------------------
// This will work for a number of form element, basically anything that
// responds to the 'change' event and whose value is set with val(), which
// should be input[type=text]
// ----------------------------------------------------------------------------

Jackalope.Client.Binding = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.prototype = {
    "init" : function ( opts ) {
        if (opts                  == undefined) return;
        if (opts["element"]       == undefined) throw new Jackalope.Error ("'element' is required");
        if (opts["property"]      == undefined) throw new Jackalope.Error ("'property' is required");

        if (typeof opts["element"] == 'string') {
            // in this case, it is assumed you have
            // passed something suitable to being
            // passed into the jQuery constructor,
            // like a CSS selector or HTML strings
            opts["element"] = jQuery( opts["element"] );
        }

        this.element       = opts["element"];
        this.target        = opts["target"];
        this.property      = opts["property"];
        this.transformer   = opts["transformer"];
        this.error_handler = opts["error_handler"] == undefined
            ? function () {}
            : opts["error_handler"];

        // private attributes
        var self = this;
        this._element_event = function () { self.update_target() };
        this._target_event  = function () { self.update_element.apply( self, arguments ) };

        this.setup();
    },
    "setup" : function () {
        if ( this.target == undefined ) return;
        this.register_element_event();
        this.register_target_event();
        this.refresh();
    },
    // user facing functions
    "set_target" : function ( target ) {
        if ( this.target != undefined ) {
            this.unregister_target_event();
            this.unregister_element_event();
        }
        this.target = target;
        this.register_element_event();
        this.register_target_event();
        this.refresh();
    },
    "clear_target" : function () {
        if ( this.target != undefined ) {
            this.unregister_target_event();
            this.unregister_element_event();
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
        try {
            var value = this.get_element_value();
            if ( this.transformer ) {
                value = this.transformer( value );
            }
            this.set_target_value( value );
        } catch (e) {
            this.error_handler( e );
        };
    },
    "update_element" : function ( target, value ) {
        this.set_element_value( value );
    },
    // -------------------------------
    // methods to change in subclasses
    // -------------------------------
    // element handlers
    "register_element_event" : function () {
        this.element.change( this._element_event );
    },
    "unregister_element_event" : function () {
        this.element.unbind( 'change', this._element_event );
    },
    "get_element_value" : function () {
        return this.element.val();
    },
    "set_element_value" : function ( value ) {
        return this.element.val( value );
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

Jackalope.Client.Binding.Label = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Label.prototype = new Jackalope.Client.Binding ();
Jackalope.Client.Binding.Label.prototype.register_element_event = function () {}; // it cannot be edited
Jackalope.Client.Binding.Label.prototype.get_element_value = function () {
    return this.element.html();
};
Jackalope.Client.Binding.Label.prototype.set_element_value = function ( value ) {
    this.element.html(value);
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Checkbox
// ----------------------------------------------------------------------------
// This will handle binding a checkbox too a boolean value
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.Checkbox = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.Checkbox.prototype = new Jackalope.Client.Binding ();
Jackalope.Client.Binding.Checkbox.prototype.get_element_value = function () {
    return this.element.attr("checked");
};
Jackalope.Client.Binding.Checkbox.prototype.set_element_value = function ( value ) {
    this.element.attr("checked", value);
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Radio Group
// ----------------------------------------------------------------------------
// This will handle binding a value from a group of radio buttons
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.RadioGroup = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.RadioGroup.prototype = new Jackalope.Client.Binding ();
Jackalope.Client.Binding.RadioGroup.prototype.get_element_value = function () {
    return this.element.filter(":checked").attr("value");
};
Jackalope.Client.Binding.RadioGroup.prototype.set_element_value = function ( value ) {
    this.element.attr("checked", false);
    this.element.filter('[value="' + value + '"]').attr("checked", true);
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Checkbox Group
// ----------------------------------------------------------------------------
// This will handle binding values to a group of checkboxes
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.CheckboxGroup = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.CheckboxGroup.prototype = new Jackalope.Client.Binding ();
Jackalope.Client.Binding.CheckboxGroup.prototype.get_element_value = function () {
    var acc = [];
    this.element.filter(":checked").map(
        function () { acc.push( $(this).attr("value") ) }
    );
    return acc;
};
Jackalope.Client.Binding.CheckboxGroup.prototype.set_element_value = function ( values ) {
    this.element.attr("checked", false);
    for (var i = 0; i < values.length; i++) {
        this.element.filter('[value="' + values[i] + '"]').attr("checked", true);
    }
};

// ----------------------------------------------------------------------------
// Jackalope Client Binding Select Pulldown
// ----------------------------------------------------------------------------
// This will handle binding values in a select pulldown
// ----------------------------------------------------------------------------

Jackalope.Client.Binding.SelectPulldown = function ( opts ) { this.init( opts ) };

Jackalope.Client.Binding.SelectPulldown.prototype = new Jackalope.Client.Binding ();
Jackalope.Client.Binding.SelectPulldown.prototype.get_element_value = function () {

};
Jackalope.Client.Binding.SelectPulldown.prototype.set_element_value = function ( values ) {

};






