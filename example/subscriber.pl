#!/usr/bin/env perl

# a ZeroMQ subscriber

use 5.014;
use ZMQx::Class;
use ZMQx::Class::AnyEvent;

my $subscriber = ZMQx::Class->socket( 'SUB', connect => 'tcp://localhost:10000' );
$subscriber->subscribe( '1' );

my $watcher = ZMQx::Class::AnyEvent->watcher( $subscriber, sub {
    while ( my $msg = $subscriber->receive ) {
        say "got $msg->[0] saying $msg->[1]";
    }
});
AnyEvent->condvar->recv;

