
test(
    "Controller Subclass test",
    function() {

        // NOTE:
        // This test actually is more about the
        // Eventful _traverse_path_and_{get|set}
        // and how it handles functions when it
        // encounters them in the chain
        // - SL

        var My = {};
        My.Controller = function () {
            this._first_name = "Stevan";
        };

        My.Controller.prototype = new Jackalope.Client.Controller ();
        My.Controller.prototype.first_name = function ( v ) {
            if (v == undefined ) return this._first_name;
            this._first_name = v;
        };

        My.Controller.prototype.chain = function () {
            return this;
        };

        (function () {
            var c = new My.Controller();

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
        })();

        (function () {
            var c = new My.Controller();

            var $input = $("<input type='text'/>");

            var binding = new Jackalope.Client.Binding ({
                element  : $input,
                target   : c,
                property : "chain.first_name"
            });

            equal($input.val(), "Stevan", "... got the right value for the DOM after initial binding");

            c.set("chain.first_name", "Steve");
            equal(c.get('chain.first_name'), "Steve", "... got the right value for updated resource");
            equal($input.val(), "Steve", "... got the right value for the DOM after changing resource");

            $input.val("Scott");
            $input.trigger('change'); // gotta manually trigger this in the test
            equal(c.get('chain.first_name'), "Scott", "... got the right value for updated resource after changing DOM");
        })();

        (function () {
            var c = new My.Controller();

            var $input = $("<input type='text'/>");

            var binding = new Jackalope.Client.Binding ({
                element  : $input,
                target   : c,
                property : "chain.chain.chain.chain.first_name"
            });

            equal($input.val(), "Stevan", "... got the right value for the DOM after initial binding");

            c.set("chain.chain.chain.chain.first_name", "Steve");
            equal(c.get('chain.chain.chain.chain.first_name'), "Steve", "... got the right value for updated resource");
            equal($input.val(), "Steve", "... got the right value for the DOM after changing resource");

            $input.val("Scott");
            $input.trigger('change'); // gotta manually trigger this in the test
            equal(c.get('chain.chain.chain.chain.first_name'), "Scott", "... got the right value for updated resource after changing DOM");
        })();

    }
);