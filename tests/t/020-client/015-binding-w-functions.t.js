
test(
    "Binding with Functions test",
    function() {

        function MyTarget () {
            this.first_name = "Stevan";
        }
        MyTarget.prototype = new Jackalope.Client.Eventful({});

        MyTarget.prototype.chain = function () { return this };

        MyTarget.prototype.get = function ( name ) {
            return this._traverse_path_and_get( name, this );
        };

        MyTarget.prototype.set = function ( name, value ) {
            this._traverse_path_and_set( name, this, value );
            this.trigger('update:' + name, this, value);
        };

        (function () {
            var c = new MyTarget();

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
            var c = new MyTarget();

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
            var c = new MyTarget();

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