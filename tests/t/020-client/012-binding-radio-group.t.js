
test(
    "Radio Group Binding test",
    function() {

        (function () {
            var r = new Jackalope.Client.Resource ({
                "id"   : "stevan",
                "body" : {
                    "first_name" : "Stevan",
                    "last_name"  : "Little",
                    "sex"        : "male"
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

            var $doc = $("<div><input type='radio' name='sex' value='male' /><input type='radio' name='sex' value='female' /></div>");

            var binding = new Jackalope.Client.Binding.Outlet.RadioGroup ({
                element  : $doc.find('input:radio'),
                target   : r,
                property : "sex"
            });

            equal(binding.get_element_value(), "male", "... got the right value for the DOM after initial binding");

            r.set({ sex : "female" });
            equal(binding.get_element_value(), "female", "... got the right value for the DOM after changing resource");

            var $male = $doc.find('input:radio[value="male"]');
            $male.attr("checked", true);
            $male.trigger('change'); // gotta manually trigger this in the test
            equal(r.get('sex'), "male", "... got the right value for updated resource after changing DOM");
        })();

    }
);