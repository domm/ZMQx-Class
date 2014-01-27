package ZMQx::RPC::Message::Response;
use strict;
use warnings;
use Carp qw(croak);
use parent qw(ZMQx::RPC::Message);

sub pack {
    my ($class, $header, @payload ) = @_;

    my $type = $header->{type} || 'string';
    my $wire_payload = $class->_encode_payload($type, \@payload);
    unshift(@$wire_payload, 200);
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

    # TODO use req_header to decode message payload
    return @$msg;

}

1;

