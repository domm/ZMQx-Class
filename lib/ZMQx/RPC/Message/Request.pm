package ZMQx::RPC::Message::Request;
use Moose;
use strict;
use warnings;
use Carp qw(croak);
extends 'ZMQx::RPC::Message';
use ZMQx::RPC::Header;
use ZMQx::RPC::Message::Response;

has 'command' => (is=>'ro',isa=>'Str',required=>1);
has '+header' => (default=>sub {
    return ZMQx::RPC::Header->new(
        type=>'string',
        timeout=>500.
    );
});


sub pack {
    my ($self, @payload ) = @_;

    my $wire_payload = $self->_encode_payload(\@payload);
    unshift(@$wire_payload, $self->command,$self->header->pack);
    return $wire_payload;
}

sub unpack {
    my ($class, $msg) = @_;

    my ($cmd,$header,@payload) = @$msg;

    my $req = $class->new(
        command=>$cmd,
        header => ZMQx::RPC::Header->unpack($header),
    );
    $req->payload($req->_decode_payload(\@payload));
    return $req;
}

sub new_response {
    my ($self, $payload ) = @_;

    return ZMQx::RPC::Message::Response->new(
        status=>200,
        header=>$self->header, # TODO extract fields relevant for response
        payload=>$payload,
    );
}

sub new_error_response {
    my ($self, $status, $error) = @_;

    return ZMQx::RPC::Message::Response->new_error(
       $status, $error, $self
    );
}

=pod

    my %payload = ( foo=>42 );
    my $msg = ZMQx::RPC::Message->pack(
        'something',
        {
            type=>'JSON',
            timeout=>1000, # milisecs
        },
        \%payload
    )
    # $msg = ['something','JSON;1000','{"foo":42}'] # payload converted to JSON

    my ($command, $header, @payload) = ZMQx::RPC::Message->unpack($msg);
    $payload[0]->{foo} # 42

    my @list = (42,'töst',47);
    my $msg2 = ZMQx::RPC::Message->pack(
        'something_else',
        { },
        @list
    )
    # $msg2 = ['something_else','string;500','42','t\303\266st','47']

    my $msg3 = ZMQx::RPC::Message->pack(
        'something_else',
        {
            type=>'raw'
        },
        slurp('foo.jpg')  # slurp() shall return the raw jpg data
    )
    # $msg3 = ['something_else','raw;500','...']

    my @payloads = ({ foo=>42 }, [ 'bar', 8 ]);
    my $msg4 = ZMQx::RPC::Message->pack(
        'cmd',
        {
            type=>'JSON'
        },
        @payloads
    )
    # $msg4 = ['cmd','JSON;1000','{"foo":42}','["bar",8]']




=cut


=pod

    my $curry = ZMQx::RPC::Message->prepare(
        'something_else',
        { },
    );
    my $msg = $curry->(@payload);

=cut



1;

