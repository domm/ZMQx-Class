use strict;
use warnings;
use 5.014;

use Test::Most;
use ZMQx::RPC::Message::Request;
use ZMQx::RPC::Message::Response;
use ZMQx::Class;
use AnyEvent;
use Data::Dumper;
use ZMQ::Constants qw(ZMQ_DONTWAIT);

package TestLoop;
use Moose;
with 'ZMQx::RPC::Loop';
sub echo {
    my ($self, @payload ) = @_;
    return map { uc($_),lc($_) } @payload;
}


package main;

my $context = ZMQx::Class->context;

subtest 'req-rep loop' => sub { 
    my $port = int(rand(64)+1).'025';
    diag("running zmq on port $port");
    my $message = "Hello";

    my $server = ZMQx::Class->socket($context, 'REP', bind =>'ipc:///tmp/test-zmqx-class-$$:'.$port );
    my $client = ZMQx::Class->socket($context, 'REQ', connect =>'ipc:///tmp/test-zmqx-class-$$:'.$port );

    my $rpc = TestLoop->new;

    my $stop = AnyEvent->timer(
        after=>5,
        cb=>sub {
             $rpc->_server_is_running(0);
        }
    );

    my $send = AnyEvent->timer(
        after=>0.2,
        cb=>sub {
            my $msg = ZMQx::RPC::Message::Request->pack('echo',{},'hello world');
            $client->send_bytes($msg);
        }
    );
    my $receive = AnyEvent->timer(
        after=>0.4,
        cb=>sub {
            my $res = $client->receive_bytes(1);
            my ($status,@payload )= ZMQx::RPC::Message::Response->unpack($res);
            is($status,200,'status: 200');
            is($payload[0],'HELLO WORLD','payload uppercase');
            is($payload[1],'hello world','payload lowercase');

            $rpc->_server_is_running(0);
        }
    );

    $rpc->loop($server);
};

done_testing();


