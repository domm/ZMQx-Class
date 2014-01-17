use strict;
use warnings;
use 5.010;
use utf8;
#use Encode;

use Test::Most;
use Devel::Peek;
use ZMQx::Class;

my $context = ZMQx::Class->context;
my $port = int(rand(64)).'025';
diag("running zmq on port $port");

my $msg = 'werde ich von Dir hören?';

ok(utf8::is_utf8($msg), "Message is unicode");
Dump($msg);
use Encode;

subtest 'req-rep tcp' => sub {
    my $server = ZMQx::Class->socket($context, 'REP', bind =>'tcp://*:'.$port );
    my $client = ZMQx::Class->socket($context, 'REQ', connect =>'tcp://localhost:'.$port );

    my @send = ('Hello','World', ($msg)x5);
    $client->send(\@send);
    my $got = $server->receive('blocking');
    #my $got = [ map { decode_utf8($_) } @{ $server->receive('blocking') } ];
    cmp_deeply($got,\@send,'got message');

    foreach (@$got) {
        ok(utf8::is_utf8($_))
    }
    Dump($got->[-1]);
    $server->send("OK");
    my ($ok) = $client->receive('block');
    ok($ok, "Received something in client");
};


done_testing();

