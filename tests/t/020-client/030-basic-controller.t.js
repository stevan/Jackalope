
test(
    "Basic Controller test",
    function() {

        var $input = $("<input type='text'/>");

        var resource = new Jackalope.Client.Resource ({
            "id"   : "stevan",
            "body" : {
                "first_name" : "Stevan",
                "last_name"  : "Little"
            },
            "version" : "fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2",
            "links"   : []
        });

        var c = new Jackalope.Client.Controller ({
            context  : resource,
            bindings : [
                new Jackalope.Client.Binding.Outlet ({
                    element  : $input,
                    property : "first_name"
                })
            ]
        });
        ok(c instanceof Jackalope.Client.Controller, "... we are an instance of Jackalope.Client.Controller");

        equal($input.val(), "Stevan", "... got the right value for the DOM after initial binding");

        c.context.set("first_name", "Steve");
        equal(c.context.get('first_name'), "Steve", "... got the right value for updated resource");
        equal($input.val(), "Steve", "... got the right value for the DOM after changing resource");

        $input.val("Scott");
        $input.trigger('change'); // gotta manually trigger this in the test
        equal(c.context.get('first_name'), "Scott", "... got the right value for updated resource after changing DOM");
    }
);