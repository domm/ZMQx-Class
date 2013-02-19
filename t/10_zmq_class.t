use strict;
use warnings;
use 5.010;

use Test::Most;

use ZMQx::Class;

my $context = ZMQx::Class->context;
isa_ok($context,'ZMQ::LibZMQ3::Context');

foreach (qw(REQ REP DEALER ROUTER PULL PUSH PUB SUB XPUB XSUB PAIR)) {
    lives_ok {
        ZMQx::Class->socket($context, $_);
    } "could init socket $_ with context";
}

foreach (qw(REQ REP DEALER ROUTER PULL PUSH PUB SUB XPUB XSUB PAIR)) {
    lives_ok {
        ZMQx::Class->socket($_);
    } "could init socket $_ without context";
}

dies_ok { ZMQx::Class->socket($context, "NOSUCHSOCK") }
    "could not init socket NOSUCHSOCK";

lives_ok {
    ZMQx::Class->socket($context, 'PULL', bind=>'tcp://*:5599');
} "init socket & bind";

lives_ok {
    ZMQx::Class->socket($context, 'PULL', connect=>'tcp://*:5599');
} "init socket & bind";

{
    my $sock;
    lives_ok {
        $sock = ZMQx::Class->socket($context, 'PULL', connect=>'tcp://*:5599', { sndtimeo=>33 });
    } "init socket with opts & bind";
    is($sock->get_sndtimeo,33,'sock opt set');
};

dies_ok {
    ZMQx::Class->socket($context, 'PULL', teleport=>'tcp://*:5599');
} "cannot init socket & teleport";

{
    my $socket = ZMQx::Class->socket($context, 'REQ');
    is($socket->type,'REQ', '$socket->type');
}

done_testing();

