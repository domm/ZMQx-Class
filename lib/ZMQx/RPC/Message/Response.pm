package ZMQx::RPC::Message::Response;
use Moose;
use strict;
use warnings;
use Carp qw(croak);
extends 'ZMQx::RPC::Message';

has 'status' => (is=>'ro',isa=>'Int'); # TODO enum
has 'request' => (is=>'ro',isa=>'ZMQx::RPC::Message::Request');

sub new_error {
    my ($class, $status, $error, $request) = @_;

    # check if $error is an object and do something..
    my %new = (
        status=>$status,
        payload=>[ ''.$error ],
        type=>'string',
    );
    $new{request} = $request if $request;
    return $class->new( %new );
}

sub add_envelope {
    my ($self, $envelope) = @_;
    unshift(@{$self->payload},@$envelope);
    return;
}

sub pack {
    my $self = shift;

    my $wire_payload = $class->_encode_payload(\@payload);
    unshift(@$wire_payload, $self->status);
    return $wire_payload;
}



sub error {
    my ($class, $status, $message ) = @_;
    # TODO do we need to handle message-objects?
    # message has to be utf-8 string
    utf8::encode(''.$message);
    return [$status,$message];
}

sub unpack {
    my ($class, $msg, $req_head) = @_;

    my $status = shift(@$msg);
    return ZMQx::RPC::Message::Response->new(
        status=>$status,
        payload=>$msg
    );

    # TODO use req_header to decode message payload

}

1;

