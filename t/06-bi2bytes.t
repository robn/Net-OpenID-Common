#!/usr/bin/perl
    
use strict;
use Test::More tests => 1080;
use Net::OpenID::Common;
use Math::BigInt;
    
for my $num (1..1080) {
    my $bi = Math::BigInt->new("$num");
    my $bytes = OpenID::util::bi2bytes($bi);
    my $bi2 = OpenID::util::bytes2bi($bytes);
    is($bi,$bi2);
}

