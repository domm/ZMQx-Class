package ZMQx::Class;
use strict;
use warnings;
use 5.010;
use ZMQx::Class::Socket;
use Carp qw(croak);

our $VERSION = "0.001";
# ABSTRACT: OO Interface to ZMQ

use ZMQ::LibZMQ3 qw(zmq_socket zmq_init);
use ZMQ::Constants qw(ZMQ_REQ ZMQ_REP ZMQ_DEALER ZMQ_ROUTER ZMQ_PULL ZMQ_PUSH ZMQ_PUB ZMQ_SUB  ZMQ_XPUB ZMQ_XSUB ZMQ_PAIR);

my %types = (
    'REQ'=>ZMQ_REQ,
    'REP'=>ZMQ_REP,
    'DEALER'=>ZMQ_DEALER,
    'ROUTER'=>ZMQ_ROUTER,
    'PULL'=>ZMQ_PULL,
    'PUSH'=>ZMQ_PUSH,
    'PUB'=>ZMQ_PUB,
    'SUB'=>ZMQ_SUB,
    'XPUB'=>ZMQ_XPUB,
    'XSUB'=>ZMQ_XSUB,
    'PAIR'=>ZMQ_PAIR,
);

sub context {
    my $class = shift;
    return zmq_init();
}

sub socket {
    my ($class, $context, $type, $connect, $address ) = @_;
    croak "no such socket type: $type" unless defined $types{$type};
    my $socket = ZMQx::Class::Socket->new(
        socket => zmq_socket($context,$types{$type}),
        type   => $type,
    );
    if ($connect && $address) {
        if ($connect eq 'bind') {
            $socket->bind($address);
        }
        elsif ($connect eq 'connect') {
            $socket->connect($address);
        }
        else {
            croak "no such connect type: $connect";
        }
    }
    return $socket;
}

1;
