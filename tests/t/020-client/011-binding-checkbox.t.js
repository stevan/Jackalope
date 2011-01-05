
test(
    "Checkbox Binding test",
    function() {

        (function () {
            var r = new Jackalope.Client.Resource ({
                "id"   : "stevan",
                "body" : {
                    "first_name" : "Stevan",
                    "last_name"  : "Little",
                    "is_awesome" : true
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

            var binding = new Jackalope.Client.Binding.Checkbox ({
                element  : "<input type='checkbox'/>",
                target   : r,
                property : "is_awesome"
            });

            equal(binding.get_element_value(), true, "... got the right value for the DOM after initial binding");

            r.set({ is_awesome : false });
            equal(binding.get_element_value(), false, "... got the right value for the DOM after changing resource");

            binding.element.attr("checked", true);
            binding.element.trigger('change'); // gotta manually trigger this in the test
            equal(r.get('is_awesome'), true, "... got the right value for updated resource after changing DOM");
        })();

    }
);