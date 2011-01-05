if (Jackalope == undefined) var Jackalope = function () {}

// ----------------------------------------------------------------------------
// Utilities
// ----------------------------------------------------------------------------
// The purpose of this module is to provide some basic utilities and to wrap
// a number of jQuery methods so that we can always replace them later.
// ----------------------------------------------------------------------------

Jackalope.Util = {
    "clone" : function ( x ) {
        if (jQuery.isArray(x)) {
            return jQuery.merge( [], x );
        } else if (jQuery.isPlainObject(x)) {
            return jQuery.extend(true, {}, x);
        } else {
            return x;
        }
    },
    "is_object" : function ( x ) {
        return jQuery.isPlainObject(x);
    },
    "is_array" : function ( x ) {
        return jQuery.isArray(x);
    },
    "Web" : {
        "ajax" : function (opts) {
            // handle setting the headers ...
            if ( opts['headers'] != undefined ) {
                var headers = delete opts['headers'];
                opts["beforeSend"] = function (xhr) {
                    for (var header in headers) {
                        xhr.setRequestHeader( header, headers[ header ] );
                    }
                };
            }
            jQuery.ajax( opts )
        }
    },
    "Array" : {
        "uniq" : function (array) {
            var r = [];
            o : for (var i = 0, n = array.length; i < n; i++) {
                for (var x = 0, y = r.length; x < y; x++) {
                    if(r[x] == array[i]) {
                        continue o;
                    }
                }
                r[r.length] = array[i];
            }
            return r;
        },
        "contains" : function (array, obj) {
            for (var i = 0; i < array.length; i++) {
                if ( array[i] == obj ) {
                    return true;
                }
            }
            return false;
        },
        "map" : function ( f, array ) {
            return jQuery.map( array, f );
        },
        "remove" : function ( array, from, to ) {
          var rest = array.slice((to || from) + 1 || array.length);
          array.length = from < 0 ? array.length + from : from;
          return array.push.apply(array, rest);
        }
    },
    "Object" : {
        "keys" : function ( obj ) {
            var acc = [];
            for (var p in obj) { acc.push( p ) }
            return acc;
        },
        "values" : function ( obj ) {
            var acc = [];
            for (var p in obj) { acc.push( obj[p] ) }
            return acc;
        },
        "key_count" : function ( obj ) {
            var count = 0;
            for (var p in obj) { count++ }
            return count;
        },
        "merge" : function ( o1, o2 ) {
            var o3 = {};
            for (var p in o2) { o3[p] = o2[p] }
            for (var p in o1) { o3[p] = o1[p] }
            return o3;
        }
    }
};

// ============================================================================


