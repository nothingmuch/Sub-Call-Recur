#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Sub::Call::Recur' => qw(:all);

sub sum {
    my ( $n, $sum ) = @_;

    if ( $n == 0 ) {
        return $sum;
    } else {
        recur ( $n - 1, $sum + 1 );
    }
}

is( sum(0, 0), 0, "0 + 0" );
is( sum(0, 1), 1, "0 + 1" );
is( sum(1, 0), 1, "1 + 0" );
is( sum(1, 1), 2, "1 + 1" );
is( sum(2, 2), 4, "2 + 2" );
is( sum(10, 1), 11, "10 + 1" );
is( sum(1000, 1), 1001, "1000 + 1" );

done_testing;

# ex: set sw=4 et:

