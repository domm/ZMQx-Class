use strict;
use warnings;
use 5.010;

use Test::Most;

use ZMQx::Helper::SocketFactory;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUBSCRIBE ZMQ_DONTWAIT);

my $context = zmq_init();

{   # push-pull
    my $pull = ZMQx::Helper::SocketFactory->make($context, 'PULL', bind =>'tcp://*:5599' );
    my $push = ZMQx::Helper::SocketFactory->make($context, 'PUSH', connect =>'tcp://localhost:5599' );
    my @send = ('Hello','World');
    $push->send_multipart(@send);
    my $got = $pull->receive_multipart('blocking');
    cmp_deeply($got,\@send,'push-pull');
}

{   # req-rep
    my $server = ZMQx::Helper::SocketFactory->make($context, 'REP', bind =>'tcp://*:5599' );
    my $client = ZMQx::Helper::SocketFactory->make($context, 'REQ', connect =>'tcp://localhost:5599' );

    my @send = ('Hello','World');
    $client->send_multipart(@send);
    my $got = $server->receive_multipart('blocking');
    cmp_deeply($got,\@send,'pub-sub');
}

done_testing();

