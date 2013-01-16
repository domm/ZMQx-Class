use strict;
use warnings;
use 5.010;

use Test::Most;

use ZMQx::Class;
use ZMQ::Constants ':all';

my $context = ZMQx::Class->context;
my $port = int(rand(64)).'025';
diag("running zmq on port $port");

my $socket = ZMQx::Class->socket($context, 'PULL', bind =>'tcp://*:'.$port );

{ # plain old set/getsockopt
    my $val = 50;
    my $got;

    lives_ok{ $socket->setsockopt(ZMQ_SNDHWM,$val) } 'setsockopt';
    lives_ok{ $got = $socket->getsockopt(ZMQ_SNDHWM) } 'getsockopt';
    is($got,$val,'got value back');
}

{ # nicer methods
    my $val = 75;
    my $got;

    lives_ok{ $socket->set_sndhwm($val) } 'set_sndhwm';
    lives_ok{ $got = $socket->get_sndhwm($val) } 'get_sndhwm';
    is($got,$val,'got value back');
}

done_testing();

