use strict;
use warnings;
use 5.010;

use Test::Most;
use ZMQx::Class;
use ZMQx::Class::AnyEvent;
use ZMQ::LibZMQ3;
use Data::Dumper;

my $context = ZMQx::Class->context;

{   # AnyEvent pub-sub
    my $port = int(rand(64)+1).'025';
    diag("running zmq on port $port");
    my $server = ZMQx::Class->socket($context, 'PUB', bind =>'tcp://*:'.$port );

    my $client1 = ZMQx::Class->socket($context, 'SUB', connect =>'tcp://localhost:'.$port );
    $client1->subscribe('');
    my $done1 = AnyEvent->condvar;
    my @got1;
    my $watcher1 = ZMQx::Class::AnyEvent->watcher($client1, sub {
        my $msgs = $client1->receive_all_multipart_messages;
        push(@got1,@$msgs);
        $done1->send if @$msgs >= 2;
    });

    my $client2 = ZMQx::Class->socket($context, 'SUB', connect =>'tcp://localhost:'.$port );
    $client2->subscribe('222');
    my $done2 = AnyEvent->condvar;
    my @got2;
    my $watcher2 = ZMQx::Class::AnyEvent->watcher($client2, sub {
        my $msgs = $client2->receive_all_multipart_messages;
        push(@got2,@$msgs);
        $done2->send if @$msgs >= 1;
    });

    sleep(1);

    my @send_1 = ('Hello','World');
    $server->send_multipart(@send_1);

    my @send_2 = ('222','foo');
    $server->send_multipart(@send_2);

    $done1->recv;
    $done2->recv;

    is(@got1,2,'client 1 got 2 messages');
    is(@got2,1,'client 2 got 1 message');

    cmp_deeply($got1[0],\@send_1,'client 1 first message = Hello World');
    cmp_deeply($got1[1],\@send_2,'client 1 second message = 222 foo');
    cmp_deeply($got2[0],\@send_2,'client 2 first message = 222 foo');
}

{   # AnyEvent req-rep using wait_for_message
    my $port = int(rand(64)+1).'025';
    diag("running zmq on port $port");
    my $message = "Hello";

    my $server = ZMQx::Class->socket($context, 'REP', bind =>'tcp://*:'.$port );

    my $client = ZMQx::Class->socket($context, 'REQ', connect =>'tcp://localhost:'.$port );
    $client->send($message);

    my $server_got = $server->receive_multipart(1);
    cmp_deeply($server_got,[$message],'Server got message');
    $server->send_multipart('ok',@$server_got);
    sleep(1);
    my $res = $client->wait_for_message;

    cmp_deeply($res,['ok',$message],'Client got response from server');
}


done_testing();

