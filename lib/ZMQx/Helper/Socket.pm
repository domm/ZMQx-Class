package ZMQx::Helper::Socket;
use strict;
use warnings;
use 5.010;

use Moose;
use namespace::autoclean;
use ZMQ::LibZMQ3 qw(zmq_bind zmq_connect zmq_recvmsg zmq_sendmsg zmq_getsockopt);
use ZMQ::Constants qw(ZMQ_FD ZMQ_SNDMORE ZMQ_RCVMORE ZMQ_DONTWAIT);

has 'socket' => (
    is=>'ro',
    isa=>'ZMQ::LibZMQ3::Socket',
    required=>1,
);

sub bind {
    my ($self, $address) = @_;
    zmq_bind($self->socket,$address);
}

sub connect {
    my ($self, $address) = @_;
    zmq_connect($self->socket,$address);
}


1;
