
test(
    "Basic Controller test",
    function() {

        var c = new Jackalope.Client.Controller ({
            _first_name : "Stevan",
            first_name  : function ( v ) {
                if (v == undefined ) return c._first_name;
                c._first_name = v;
            }
        });
        ok(c instanceof Jackalope.Client.Controller, "... we are an instance of Jackalope.Client.Controller");

        var $input = $("<input type='text'/>");

        var binding = new Jackalope.Client.Binding ({
            element  : $input,
            target   : c,
            property : "first_name"
        });

        equal($input.val(), "Stevan", "... got the right value for the DOM after initial binding");

        c.set("first_name", "Steve");
        equal(c.get('first_name'), "Steve", "... got the right value for updated resource");
        equal($input.val(), "Steve", "... got the right value for the DOM after changing resource");

        $input.val("Scott");
        $input.trigger('change'); // gotta manually trigger this in the test
        equal(c.get('first_name'), "Scott", "... got the right value for updated resource after changing DOM");
    }
);