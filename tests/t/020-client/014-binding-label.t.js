
test(
    "Label Binding test",
    function() {

        (function () {
            var r = new Jackalope.Client.Resource ({
                "id"   : "stevan",
                "body" : {
                    "first_name" : "Stevan",
                    "last_name"  : "Little"
                },
                "version" : "fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2",
                "links"   : [
                    { "rel" : "create", "href" : "/",  "method" : "POST"   },
                    { "rel" : "delete", "href" : "/1", "method" : "DELETE" },
                    { "rel" : "edit",   "href" : "/1", "method" : "PUT"    },
                    { "rel" : "list",   "href" : "/",  "method" : "GET"    },
                    { "rel" : "read",   "href" : "/1", "method" : "GET"    }
                ]
            });


            var $doc   = $("<div><span class='name'></span><input type='text'/></div>");
            var $input = $doc.find('input');
            var $label = $doc.find('.name');

            var b1 = new Jackalope.Client.Binding.Outlet ({
                element  : $input,
                target   : r,
                property : "first_name"
            });

            var b2 = new Jackalope.Client.Binding.Outlet.Label ({
                element  : $label,
                target   : r,
                property : "first_name"
            });

            equal($input.val(), "Stevan", "... got the right value for the DOM after initial binding");
            equal($label.text(), "Stevan", "... got the right value for the DOM after initial binding");

            r.set({ first_name : "Steve" });
            equal($input.val(), "Steve", "... got the right value for the DOM after changing resource");
            equal($label.text(), "Steve", "... got the right value for the DOM after changing resource");

            $input.val("Scott");
            $input.trigger('change'); // gotta manually trigger this in the test
            equal(r.get('first_name'), "Scott", "... got the right value for updated resource after changing DOM");
            equal($label.text(), "Scott", "... got the right value for updated resource after changing DOM");
        })();

    }
);