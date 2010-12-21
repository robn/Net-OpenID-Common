
package Net::OpenID::Common;

=head1 NAME

Net::OpenID::Common - Libraries shared between Net::OpenID::Consumer and Net::OpenID::Server

=head1 DESCRIPTION

The Consumer and Server implementations share a few libraries which live with this module. This module is here largely to hold the version number and this documentation, though it also incorporates some utility functions inherited from previous versions of L<Net::OpenID::Consumer>.

=head1 COPYRIGHT

This package is Copyright (c) 2005 Brad Fitzpatrick, and (c) 2008 Martin Atkins. All rights reserved.

You may distribute under the terms of either the GNU General Public License or the Artistic License, as specified in the Perl README file. If you need more liberal licensing terms, please contact the maintainer.

=head1 MAINTAINER

Maintained by Martin Atkins <mart@degeneration.co.uk>

=cut

# This package should totally be called Net::OpenID::util, but
# it was historically named wrong so we're just leaving it
# like this to avoid confusion.
package OpenID::util;

use Crypt::DH::GMP;
use Math::BigInt;
use Time::Local ();
use MIME::Base64 ();
use JSON qw(encode_json);

use constant VERSION_1_NAMESPACE => "http://openid.net/signon/1.1";
use constant VERSION_2_NAMESPACE => "http://specs.openid.net/auth/2.0";

# I guess this is a bit daft since constants are subs anyway,
# but whatever.
sub version_1_namespace {
    return VERSION_1_NAMESPACE;
}
sub version_2_namespace {
    return VERSION_2_NAMESPACE;
}
sub version_1_xrds_service_url {
    return VERSION_1_NAMESPACE;
}
sub version_2_xrds_service_url {
    return "http://specs.openid.net/auth/2.0/signon";
}
sub version_2_xrds_directed_service_url {
    return "http://specs.openid.net/auth/2.0/server";
}
sub version_2_identifier_select_url {
    return "http://specs.openid.net/auth/2.0/identifier_select";
}

sub parse_keyvalue {
    my $reply = shift;
    my %ret;
    $reply =~ s/\r//g;
    foreach (split /\n/, $reply) {
        next unless /^(\S+?):(.*)/;
        $ret{$1} = $2;
    }
    return %ret;
}

# Data::Dumper for JavaScript
sub js_dumper {
    my $obj = shift;
    return encode_json($obj);
}

sub eurl
{
    my $a = $_[0];
    $a =~ s/([^a-zA-Z0-9_\,\-.\/\\\: ])/uc sprintf("%%%02x",ord($1))/eg;
    $a =~ tr/ /+/;
    return $a;
}

sub push_url_arg {
    my $uref = shift;
    $$uref =~ s/[&?]$//;
    my $got_qmark = ($$uref =~ /\?/);

    while (@_) {
        my $key = shift;
        my $value = shift;
        $$uref .= $got_qmark ? "&" : ($got_qmark = 1, "?");
        $$uref .= eurl($key) . "=" . eurl($value);
    }
}

sub push_openid2_url_arg {
    my $uref = shift;
    my %args = @_;
    push_url_arg($uref,
        'openid.ns' => VERSION_2_NAMESPACE,
        map {
            'openid.'.$_ => $args{$_}
        } keys %args,
    );
}

sub time_to_w3c {
    my $time = shift || time();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
    $mon++;
    $year += 1900;

    return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",
                   $year, $mon, $mday,
                   $hour, $min, $sec);
}

sub w3c_to_time {
    my $hms = shift;
    return 0 unless
        $hms =~ /^(\d{4,4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)Z$/;

    my $time;
    eval {
        $time = Time::Local::timegm($6, $5, $4, $3, $2 - 1, $1);
    };
    return 0 if $@;
    return $time;
}

sub int2bytes {
    my ($int) = @_;

    my $bigint = Math::BigInt->new($int);

    die "Can't deal with negative numbers" if $bigint->is_negative;

    my $bits = $bigint->as_bin;
    die unless $bits =~ s/^0b//;

    # prepend zeros to round to byte boundary, or to unset high bit
    my $prepend = (8 - length($bits) % 8) || ($bits =~ /^1/ ? 8 : 0);
    $bits = ("0" x $prepend) . $bits if $prepend;

    return pack("B*", $bits);
}

sub int2arg {
    return b64(int2bytes($_[0]));
}

sub b64 {
    my $val = MIME::Base64::encode_base64($_[0]);
    $val =~ s/\s+//g;
    return $val;
}

sub d64 {
    return MIME::Base64::decode_base64($_[0]);
}

sub bytes2int {
    return Math::BigInt->new("0b" . unpack("B*", $_[0]))->bstr;
}

sub arg2int {
    my ($arg) = @_;
    return undef unless defined $arg and $arg ne "";
    # don't acccept base-64 encoded numbers over 700 bytes.  which means
    # those over 4200 bits.
    return 0 if length($arg) > 700;
    return bytes2int(MIME::Base64::decode_base64($arg));
}

sub timing_indep_eq {
    my ($x, $y)=@_;

    return '' if length($x)!=length($y);

    my $n=length($x);

    my $result=0;
    for (my $i=0; $i<$n; $i++) {
        $result |= ord(substr($x, $i, 1)) ^ ord(substr($y, $i, 1));
    }

    return !$result;
}

sub get_dh {
    my ($p, $g) = @_;

    $p ||= "155172898181473697471232257763715539915724801966915404479707795314057629378541917580651227423698188993727816152646631438561595825688188889951272158842675419950341258706556549803580104870537681476726513255747040765857479291291572334510643245094715007229621094194349783925984760375594985848253359305585439638443";
    $g ||= "2";

    return if $p <= 10 or $g <= 1;

    my $dh = Crypt::DH::GMP->new(p => $p, g => $g);
    $dh->generate_keys;

    return $dh;
}

1;
