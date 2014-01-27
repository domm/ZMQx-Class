use strict;
use warnings;
use 5.014;

use Test::Most;
use ZMQx::RPC::Message::Request;

subtest 'defaults' => sub {
    my $msg = ZMQx::RPC::Message::Request->pack('cmd',{},'hello world');
    is($msg->[0],'cmd','command');
    is($msg->[1],'string;500','header');
    is($msg->[2],'hello world','payload');
};

done_testing();

