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
use JSON::XS;
with 'ZMQx::RPC::Loop'; # TODO: define allowed methods
sub echo {
    my ($self, @payload ) = @_;
    return map { uc($_),lc($_) } @payload;
}


package main;

my $context = ZMQx::Class->context;
my $port = int(rand(64)+1).'025';
my $endpoint = "ipc:///tmp/test-zmqx-class-$$:".$port;

diag("running zmq on $endpoint");

my $server = ZMQx::Class->socket($context, 'REP', bind =>$endpoint );
my $client = ZMQx::Class->socket($context, 'REQ', connect =>$endpoint);

my $rpc = TestLoop->new;

my $stop = AnyEvent->timer(
    after=>5,
    cb=>sub {
        diag "killed server and tests after 5 secs";
        $rpc->_server_is_running(0);
    }
);

my $send1 = AnyEvent->timer(
    after=>0.2,
    cb=>sub {
        my $msg = ZMQx::RPC::Message::Request->new(command=>'echo');
        $client->send_bytes($msg->pack('hello world'));
    }
);
my $receive1 = AnyEvent->timer(
    after=>0.4,
    cb=>sub {
        my $raw = $client->receive_bytes(1);
        my $res = ZMQx::RPC::Message::Response->unpack($raw);
        is($res->status,200,'status: 200');
        is($res->header->type,'string','header->type');
        is($res->payload->[0],'HELLO WORLD','payload string uppercase');
        is($res->payload->[1],'hello world','payload string lowercase');

    }
);

my $send2 = AnyEvent->timer(
    after=>0.6,
    cb=>sub {
        my $msg = ZMQx::RPC::Message::Request->new(
            command=>'echo',
            header=>ZMQx::RPC::Header->new(type=>'JSON'),
        );
        $client->send_bytes($msg->pack({foo=>'bar'},{foo=>42}));
    }
);
my $receive2 = AnyEvent->timer(
    after=>0.9,
    cb=>sub {
        my $raw = $client->receive_bytes(1);
        my $res = ZMQx::RPC::Message::Response->unpack($raw);
        is($res->status,200,'status: 200');
        is($res->header->type,'JSON','header->type');
        is($res->payload->[0]{FOO},'BAR','payload JSON uppercase');
        is($res->payload->[1]{foo},'bar','payload JSON lowercase');
        is($res->payload->[2]{FOO},42,'payload JSON uppercase');
        is($res->payload->[3]{foo},42,'payload JSON lowercase');

        $rpc->_server_is_running(0);
    }
);

$rpc->loop($server);

done_testing();






