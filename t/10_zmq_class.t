use strict;
use warnings;
use 5.010;

use Test::Most;

use ZMQx::Class;

subtest 'init socket without context' => sub {
    foreach (qw(REQ REP DEALER ROUTER PULL PUSH PUB SUB XPUB XSUB PAIR)) {
        lives_ok {
            ZMQx::Class->socket($_);
        } "$_";
    }
};

subtest 'init socket with context' => sub {
    my $context = ZMQx::Class->context;
    isa_ok($context,'ZMQ::LibZMQ3::Context');

    foreach (qw(REQ REP DEALER ROUTER PULL PUSH PUB SUB XPUB XSUB PAIR)) {
        lives_ok {
            ZMQx::Class->socket($context, $_);
        } "$_";
    }
};

subtest 'init, bind/connect, opts' => sub {
    lives_ok {
        ZMQx::Class->socket('PULL', bind=>'tcp://*:5599');
    } "bind";

    lives_ok {
        ZMQx::Class->socket('PULL', connect=>'tcp://*:5599');
    } "connect";

    {
        my $sock;
        lives_ok {
            $sock = ZMQx::Class->socket('PULL', connect=>'tcp://*:5599', { sndtimeo=>33 });
        } "connect & opts";
        is($sock->get_sndtimeo,33,'sock opt set');
    };
};


subtest 'die & other corner cases' => sub {
    dies_ok { ZMQx::Class->socket("NOSUCHSOCK") }
        "could not init socket NOSUCHSOCK";

    dies_ok {
        ZMQx::Class->socket('PULL', teleport=>'tcp://*:5599');
    } "cannot init socket & teleport";

    {
        my $sock = ZMQx::Class->socket('PULL', 'bind');
        is($sock->_connected,0,'not connected');
    }


    warning_is {
        ZMQx::Class->socket('PULL', bind=>'tcp://*:5599',{nosuchopt=>123});
    } "no such sockopt nosuchopt";

};

done_testing();

