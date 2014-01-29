use strict;
use warnings;
use 5.014;

use Test::Most;
use ZMQx::RPC::Message::Response;
use ZMQx::RPC::Header;
use JSON::XS;

subtest 'defaults' => sub {
    my $msg = ZMQx::RPC::Message::Response->new(
        status=>200,
        payload=>['hello','world']
    );
    my $packed = $msg->pack;
    is($packed->[0],200,'status');
    is($packed->[1],'string;','header (no timeout)');
    is($packed->[2],'hello','payload');
    is($packed->[3],'world','payload');
};

subtest 'unpack JSON' => sub {
    my $msg = ZMQx::RPC::Message::Response->unpack([
        200,
        'JSON;',
        '{"hase":"baer"}',
    ]);
    is($msg->status,200,'unpack: status');
    explain($msg);
    is($msg->payload->{hase},'baer','unpack: JSON payload');

};

done_testing();
__END__


subtest 'custom header' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command=>'cmd',
        header => ZMQx::RPC::Header->new(
            timeout=>42,
            type=>'JSON',
        ),
    );
    my $packed = $msg->pack(['hello','world']);
    is($packed->[0],'cmd','command');
    is($packed->[1],'JSON;42','header');
    is($packed->[2],'["hello","world"]','payload is JSON');


    my $unpacked = ZMQx::RPC::Message::Request->unpack($packed);
    is($unpacked->command,'cmd','unpack: command');
    is($unpacked->header->timeout,42,'unpack: header.timeout');
    is($unpacked->payload->[1],'world','unpack: payload is a data structure');
    explain $unpacked->payload;
};


subtest 'new_response' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command=>'cmd',
    );
    my $res = $msg->new_response(["hase"]);
    is($res->header->type,'string','new response: header.type');
};

subtest 'new_response JSON' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command=>'cmd',
        header => ZMQx::RPC::Header->new(
            type=>'JSON',
        ),
    );
    my $res = $msg->new_response([{ hash=>'ref' }]);
    is($res->header->type,'JSON','new response: header.type');

    my $packed = $res->pack;
    is($packed->[0],200,'response status ok');
    is($packed->[2],'{"hash":"ref"}','response packed payload is JSON string');

};

subtest 'new_error_response' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command=>'cmd',
    );
    my $res = $msg->new_error_response(500, 'err');
    is($res->status,500,'new error response: status');
    is($res->header->type,'string','new error response: header.type');
};

subtest 'new_error_response JSON' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command=>'cmd',
        header => ZMQx::RPC::Header->new(
            type=>'JSON',
        ),
    );
    my $res = $msg->new_error_response(500, 'err');
    is($res->status,500,'new error response: status');
    is($res->header->type,'string','new error response: header.type still string');
};

done_testing();

