#!perl

use strict;
use warnings;

use Template;
use Jackalope::Schema::Spec;

my $output;
my $tt = Template->new;
$tt->process(
    \*DATA,
    {
        spec    => Jackalope::Schema::Spec->new->get_spec,
        reftype => sub { ref( $_[0] ) },
    },
    \$output
) || die $tt->error;

sub { [ 200, [], [ $output ]] };

__DATA__
[%
    SET ref_marker = '$ref';
    MACRO process_property ( prop ) BLOCK;
        %]<table cellpadding="3" cellspacing="5" border="0" style="border:1px solid #888888">[%
            FOREACH key IN prop.keys.sort.reverse;
                SET value = prop.$key;
                %]
                <tr>
                <td valign="top" align="right" style="border-right:1px dashed #888888">
                    <div style="color: #888888; padding-right: 5px">[% key %]</div>
                </td>
                <td valign="top">
                [%
                    IF reftype(value) == 'ARRAY';
                        value.join(', ');
                    ELSIF reftype(value) == 'HASH';
                        process_property(value);
                    ELSE;
                        IF key == ref_marker;
                            %]<a href="javascript:void(0)" onclick="show_schema_desc('[% value %]')">[% value %]</a>[%
                        ELSE;
                            value.replace('\n', ' ');
                        END;
                    END;
                %]
                </td>
                </tr>
                [%
            END;
        %]</table>[%
    END;
%]
<html>
<head>
<title>Jackalope Spec Viewer</title>
<script type="text/javascript">
var last_shown;
function show_schema_desc (name) {
    if (name == '--') return;
    if (last_shown != undefined) {
        document.getElementById(last_shown).style.display = 'none';
    }
    document.getElementById(name).style.display = 'block';
    last_shown = name;
}
</script>
</head>
<body>
<h1>Jackalope Spec Viewer</h1>
<select id="schema_list" onchange="show_schema_desc( this.options[ this.selectedIndex ].value )">
    <option>--</option>
    [% FOREACH uri IN spec.schema_map.keys.sort %]
        <option value="[% uri %]">[% uri %]</option>
    [% END %]
</select>
[% FOREACH uri IN spec.schema_map.keys %]
    [% SET schema = spec.schema_map.$uri %]
    <div id="[% uri %]" style="display:none;">
        <h2>[% schema.id %]</h2>
        <h3>[% schema.title %]</h3>
        <p>[% schema.description.replace('\n', ' ') %]</p>
        <table border="0">
        [% IF schema.extends %]
            <tr>
                <td>Extends</td>
                <td>
                    <a href="javascript:void(0)" onclick="show_schema_desc('[% schema.extends.$ref_marker %]')">[% schema.extends.$ref_marker %]</a>
                </td>
            </tr>
        [% END %]
        [% IF schema.properties %]
            <tr>
                <td valign="top">Properties</td>
                <td>[% process_property(schema.properties) %]</td>
            </tr>
        [% END %]
        [% IF schema.additional_properties %]
            <tr>
                <td valign="top">Additional Properties</td>
                <td>[% process_property(schema.additional_properties) %]</td>
            </tr>
        [% END %]
        </table>
    </div>
[% END %]
</body>
</html>



