package ZMQx::RPC::Message::Response;
use Moose;
use strict;
use warnings;
use Carp qw(croak);
extends 'ZMQx::RPC::Message';

has 'status' => (is=>'ro',isa=>'Int'); # TODO enum
has 'request' => (is=>'ro',isa=>'ZMQx::RPC::Message::Request');
has '+header' => (default=>sub {
    return ZMQx::RPC::Header->new(
        type=>'string',
    );
});

sub new_error {
    my ($class, $status, $error, $request) = @_;

    # check if $error is an object and do something..
    my %new = (
        status=>$status,
        payload=>[ ''.$error ],
    );
    $new{request} = $request if $request;
    return $class->new( %new );
}

sub pack {
    my $self = shift;

    my $wire_payload = $self->_encode_payload($self->payload);
    unshift(@$wire_payload, $self->status, $self->header->pack);
    return $wire_payload;
}

sub unpack {
    my ($class, $msg) = @_;

    my $status = shift(@$msg);
    my $header = shift(@$msg);
    my $res = ZMQx::RPC::Message::Response->new(
        status=>$status,
        header => ZMQx::RPC::Header->unpack($header),
    );
    $res->_decode_payload($msg);
    return $res;
}

1;

