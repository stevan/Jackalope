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
        if (opts["resource"]      == undefined) throw new Jackalope.Error ("'resource' is required");
        if (opts["property"]      == undefined) throw new Jackalope.Error ("'property' is required");

        if (typeof opts["element"] == 'string') {
            // in this case, it is assumed you have
            // passed something suitable to being
            // passed into the jQuery constructor,
            // like a CSS selector or HTML strings
            opts["element"] = jQuery( opts["element"] );
        }

        this.element       = opts["element"];
        this.resource      = opts["resource"];
        this.property      = opts["property"];
        this.error_handler = opts["error_handler"] == undefined
            ? function () {}
            : opts["error_handler"];

        this.setup();
    },
    "setup" : function () {
        var self = this;
        this.register_element_event(
            function () { self.update_resource() }
        );
        this.register_resource_event(
            function () { self.update_element.apply( self, arguments ) }
        );
        this.update_element( this.resource, this.get_resource_value() );
    },
    // element handlers
    "register_element_event" : function ( e ) {
        this.element.change( e );
    },
    "get_element_value" : function () {
        return this.element.val();
    },
    "set_element_value" : function ( value ) {
        return this.element.val( value );
    },
    // resource handlers
    "register_resource_event" : function ( e ) {
        this.resource.bind( "update:" + this.property, e );
    },
    "get_resource_value" : function () {
        return this.resource.get( this.property );
    },
    "set_resource_value" : function ( value ) {
        var changes = {};
        changes[ this.property ] = value;
        return this.resource.set( changes );
    },
    // default events
    "update_resource" : function () {
        try {
            this.set_resource_value( this.get_element_value() );
        } catch (e) {
            this.error_handler.apply( this, e );
        };
    },
    "update_element" : function ( resource, value ) {
        this.set_element_value( value );
    }
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









