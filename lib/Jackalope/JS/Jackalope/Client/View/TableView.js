if (Jackalope             == undefined) var Jackalope             = function () {}
if (Jackalope.Client      == undefined)     Jackalope.Client      = function () {}
if (Jackalope.Client.View == undefined)     Jackalope.Client.View = function () {}

// ----------------------------------------------------------------------------
// Jackalope Client View TableView
// ----------------------------------------------------------------------------

Jackalope.Client.View.TableView = function ( opts ) {
    this.$table        = jQuery( opts["table_body"] );
    this.$row_template = this.$table.find( opts["row_selector"] ).clone(true);
    this.$table.empty();

    this.row_selector = opts["row_selector"];
    this.data_source  = opts["data_source"];
    this.binding_spec = opts["binding_spec"];

    this.init();
};

Jackalope.Client.View.TableView.prototype = new Jackalope.Client.Observable ();

Jackalope.Client.View.TableView.prototype.init = function () {
    for (var i = 0; i < this.data_source.length(); i++) {
        this.add_new_row( i );
    }
};

Jackalope.Client.View.TableView.prototype.reload = function () {
    this.$table.empty();
    this.init();
};

Jackalope.Client.View.TableView.prototype.add_new_row = function ( index ) {
    var self     = this;
    var $new_row = this.$row_template.clone(true);

    this.data_source.bind(
        'update:' + index,
        function ( c, idx, r ) { self.populate_row( $new_row, idx, r ) }
    );

    this.populate_row( $new_row, index, this.data_source.get( index ) )
    this.$table.append( $new_row );
};

Jackalope.Client.View.TableView.prototype.populate_row = function ( $row, index, element ) {
    for ( var selector in this.binding_spec ) {
        var property = this.binding_spec[ selector ];
        $row.find( selector ).html( element.get( property ) );
    }
    var self = this;
    $row.click(function () {
        $(this).siblings().removeClass('selected');
        $(this).addClass('selected');
        self.trigger('selected', index)
    });
};

Jackalope.Client.View.TableView.prototype.clear_selection = function () {
    this.$table.find( this.row_selector ).removeClass('selected');
};


