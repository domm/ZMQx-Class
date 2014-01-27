package ZMQx::RPC::Message;
use strict;
use warnings;
use Moose;
use Carp qw(croak);

has 'serializable_types' => (is=>'ro',default=>sub {{
    'JSON'=>\&JSON::XS::encode_json,
}});
has 'payload' => (is=>'rw',isa=>'ArrayRef',default=>sub {[]});

# TODO specify header position via trait
has 'type' => (is=>'ro',isa=>'Str',default=>'string'); # TODO enum? serializable_types?



sub _encode_payload {
    my ($self, $payload ) = @_;
    my $type = $self->type;
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
    elsif (my $serializer = $self->serializable_types->{$type}) {
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

