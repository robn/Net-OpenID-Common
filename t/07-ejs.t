#!/usr/bin/perl
    
use strict;
use Test::More 'no_plan';
use Net::OpenID::Common;

my @escapes = qw(
    "'\\    \"\'\\\\
);

while ( my ($before, $after) = splice @escapes, 0, 2 ) {
    is ( $after, OpenID::util::ejs($before) );
}
