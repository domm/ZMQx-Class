package ZMQx::RPC::Message;
use strict;
use warnings;
use Carp qw(croak);

my @header_positions = qw( type timeout );
my %serializable_types = (
    'JSON'=>\&JSON::XS::encode_json,
);

sub pack {
    my ($class, $command, $header, @payload ) = @_;

    # we could do my $msg = $class->new($command, $header, @payload);
    # and then $msg->pack
    # but for now we just do the pack right away

    my $type = $header->{type} ||= 'string';
    $header->{timeout} ||= '500';

    my @head;
    foreach my $fld (@header_positions) {
        if (my $v = $header->{$fld}) {
            push(@head, $v);
           # delete $header->{$fld});
        }
        else {
            push(@head, '')
        }
    }
    # TODO warn if there is still something left in header

    my @wire_payload;
    if ($type eq 'string' || $type eq 'raw') {
        while (my ($index, $val) = each (@payload)) {
            croak("ref not allowed in string/raw message at pos $index") if ref($val);
            # TODO allow string ref so we can send DVD images :-)
            push(@wire_payload, $val);
            if ($type eq 'string') {
                # converts characters to utf8
                utf8::encode($wire_payload[-1]);
            }
            else {
                # will croak if contains code points > 255
                utf8::downgrade($wire_payload[-1]);
            }
        }
    }
    elsif (my $serializer = $serializable_types{$type}) {
        @wire_payload = map {
            ref($_) ? $serializer->($_) : $_
        } @payload;
    }
    else {
        croak "type >$type< not defined";
    }

    return [$command,join(';',@head),@wire_payload];
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

