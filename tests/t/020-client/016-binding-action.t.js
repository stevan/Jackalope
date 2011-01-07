
test(
    "Action Binding test",
    function() {

        var object = {
            // data
            counter : 0,
            // methods
            test_one : function () {
                ok(this === object, '... got the right context');
            },
            test_two : function () {
                this.counter++
            }
        };

        (function () {
            var a = new Jackalope.Client.Binding.Action ({
                element       : $('<input type="button" />'),
                event_type    : 'click',
                target        : object,
                target_action : 'test_one'
            });

            a.element.click();
        })();

        (function () {
            var a = new Jackalope.Client.Binding.Action ({
                element       : $('<input type="button" />'),
                event_type    : 'click',
                target_action : 'test_two'
            });

            equal(object.counter, 0, '... the counter is 0');
            a.element.click();
            equal(object.counter, 0, '... the counter is 0');

            a.set_target( object );
            a.element.click();
            equal(object.counter, 1, '... the counter is 1');

            a.clear_target();
            a.element.click();
            equal(object.counter, 1, '... the counter is 1');

            a.set_target( object );
            a.element.click();
            equal(object.counter, 2, '... the counter is 2');

        })();

    }
);