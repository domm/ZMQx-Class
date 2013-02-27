use strict;
use warnings;
use 5.010;

use Test::Most;

use ZMQx::Class;
use ZMQ::Constants ':all';

my $context = ZMQx::Class->context;
my $port = int(rand(64)).'025';
diag("running zmq on port $port");

my $socket = ZMQx::Class->socket($context, 'PULL' );

subtest 'plain old set/getsockopt' => sub {
    my $val = 50;
    my $got;

    lives_ok{ $socket->setsockopt(ZMQ_SNDHWM,$val) } 'setsockopt';
    lives_ok{ $got = $socket->getsockopt(ZMQ_SNDHWM) } 'getsockopt';
    is($got,$val,'got value back');
};

subtest 'nice set/get methods' => sub {
    my $val = 75;
    my $got;

    lives_ok{ $socket->set_sndhwm($val) } 'set_sndhwm';
    lives_ok{ $got = $socket->get_sndhwm } 'get_sndhwm';
    is($got,$val,'got value back');
};

subtest 'warn after connect' => sub {
    my $socket2 = ZMQx::Class->socket($context, 'PULL', bind =>'tcp://*:'.$port );
    warning_is { $socket2->set_sndhwm(12); } "Setting 'ZMQ_SNDHWM' only works before connect/bind. Value not stored!", 'got a warning';
    is($socket2->get_sndhwm,'1000','get did not work');
};

done_testing();

