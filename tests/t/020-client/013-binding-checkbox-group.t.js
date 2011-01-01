
test(
    "Checkbox Group Binding test",
    function() {

        (function () {
            var r = new Jackalope.Client.Resource ({
                "id"   : "stevan",
                "body" : {
                    "first_name" : "Stevan",
                    "last_name"  : "Little",
                    "titles"     : ["programmer","manager"]
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

            var $doc = $("<div>"
                       + "<input type='checkbox' name='title' value='programmer' />"
                       + "<input type='checkbox' name='title' value='manager' />"
                       + "<input type='checkbox' name='title' value='sysadmin' />"
                       + "</div>");

            var binding = new Jackalope.Client.Binding.CheckboxGroup ({
                element  : $doc.find('input:checkbox'),
                resource : r,
                property : "titles"
            });

            deepEqual(binding.get_element_value(), ["programmer","manager"], "... got the right value for the DOM after initial binding");

            r.set({ titles : ["programmer","sysadmin"] });
            deepEqual(binding.get_element_value(), ["programmer","sysadmin"], "... got the right value for the DOM after changing resource");

            var $manager = $doc.find('input:checkbox[value="manager"]');
            $manager.attr("checked", true);
            $manager.trigger('change'); // gotta manually trigger this in the test
            deepEqual(r.get('titles'), ["programmer","manager","sysadmin"], "... got the right value for updated resource after changing DOM");
        })();

    }
);