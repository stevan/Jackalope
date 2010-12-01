package Test::Jackalope;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Test::Builder ();
use Data::Dumper  ();
use Sub::Exporter;

my @exports = qw/
    validation_pass
    validation_fail
/;

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

our $Test = Test::Builder->new;

sub validation_pass {
    my ($result, $message) = @_;
    if (exists $result->{error}) {
        $Test->ok(0, $message);
        $Test->diag("... validation did not pass\n" .
                    "   error: '" . _dump_result( $result ));
    }
    else {
        $Test->ok(1, $message);
    }
}

sub validation_fail {
    my ($result, $message) = @_;
    if (exists $result->{error}) {
        $Test->ok(1, $message);
    }
    else {
        $Test->ok(0, $message);
        $Test->diag("... validation passed, but was expected to fail");
    }
}

sub _dump_result {
    my ($result) = @_;
    local $Data::Dumper::Indent = 0;
    my $out = Data::Dumper::Dumper($result);
    $out =~ s/\$VAR\d\s*=\s*//;
    return $out;
}

1;

__END__

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
