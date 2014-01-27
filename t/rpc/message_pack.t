use strict;
use warnings;
use 5.014;

use Test::Most;
use ZMQx::RPC::Message::Request;

subtest 'request defaults' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command=>'cmd',
        #type=>
        #timeout=>
    );
    my $packed = $msg->pack('hello world');
    is($packed->[0],'cmd','command');
    is($packed->[1],'string;500','header');
    is($packed->[2],'hello world','payload');
};

subtest 'response defaults' => sub {
    my $msg = ZMQx::RPC::Message::Response->new(
        command=>'cmd',
        #type=>
        #timeout=>
    );
    my $packed = $msg->pack('hello world');
    is($packed->[0],'cmd','command');
    is($packed->[1],'string;500','header');
    is($packed->[2],'hello world','payload');
};



done_testing();

