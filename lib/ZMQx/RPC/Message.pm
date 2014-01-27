package ZMQx::RPC::Message;
use strict;
use warnings;
use Carp qw(croak);

my %serializable_types = (
    'JSON'=>\&JSON::XS::encode_json,
);

sub _encode_payload {
    my ($class, $type, $payload ) = @_;
    my @wire_payload;
    if ($type eq 'string' || $type eq 'raw') {
        while (my ($index, $val) = each (@$payload)) {
            croak("ref not allowed in string/raw message at pos $index") if ref($val);
            # TODO allow string ref so we can send DVD images :-)
            push(@wire_payload, $val);
            if ($type eq 'string') {
                # converts characters to utf8
                utf8::encode($wire_payload[-1]);
            }
            else {
                # will croak if contains code points > 255
                utf8::downgrade($wire_payload[-1]);
            }
        }
    }
    elsif (my $serializer = $serializable_types{$type}) {
        @wire_payload = map {
            ref($_) ? $serializer->($_) : $_
        } @$payload;
    }
    else {
        croak "type >$type< not defined";
    }
    return \@wire_payload;
}

1;

