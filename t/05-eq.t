#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use Test::More tests=>14;

use Net::OpenID::Common;

compare_comparisons('x', 'x', 'same, 1 char');
compare_comparisons('x', 'y', 'different, 1 char');

compare_comparisons('xx', 'xx', 'same, 2 chars');
compare_comparisons('xx', 'xy', 'different, 2 chars');

compare_comparisons('Frække frølår', 'Frække frølår', 'same, utf-8');
compare_comparisons('Frøkke frålær', 'Frække frølår', 'different, utf-8');

my $x='x' x 1000000;
my $y='y' . 'x' x 999999;
compare_comparisons($x, $x, 'same, 1M chars');
compare_comparisons($x, $y, 'different, 1M chars');

my $z='x' x 999999;
compare_comparisons( $x,   $z, 'different lengths, long');
compare_comparisons('a', 'aa', 'different lengths, short');
compare_comparisons( '',  'a', 'different lengths, shortest');

compare_comparisons( '',  '', 'same length, shortest');

compare_comparisons(undef,  '', 'undef, empty string');
compare_comparisons(undef, undef, 'both undef');

1;

sub compare_comparisons {
    my ($first, $second, $description)=@_;

    # XXX undefs make icky warnings but still need to be tested.
    # possibly we should make timing_indep_eq produce exactly the same
    # warnings as eq when faced with undefs, and then we should test
    # the warnings. that seems like too much effort
    no warnings 'uninitialized';

    is( ($first eq $second), OpenID::util::timing_indep_eq($first, $second), $description);
}
