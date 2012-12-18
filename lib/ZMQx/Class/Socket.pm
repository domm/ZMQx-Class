package ZMQx::Class::Socket;
use strict;
use warnings;
use 5.010;

use Moose;
use namespace::autoclean;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_FD ZMQ_SNDMORE ZMQ_RCVMORE ZMQ_DONTWAIT);

has 'socket' => (
    is=>'ro',
    isa=>'ZMQ::LibZMQ3::Socket',
    required=>1,
);

sub bind {
    my ($self, $address) = @_;
    zmq_bind($self->socket,$address);
}

sub connect {
    my ($self, $address) = @_;
    zmq_connect($self->socket,$address);
}

sub setsockopt {
    my $self = shift;
    zmq_setsockopt($self->socket, @_);
}

sub send {
    my ($self, $msg) = @_;
    zmq_sendmsg( $self->socket, $msg);
}

sub send_multipart {
    my ($self, @parts) = @_;
    my $socket = $self->socket;
    my $last = pop(@parts);
    foreach (@parts) {
        zmq_sendmsg( $socket, $_, ZMQ_SNDMORE );
    }
    zmq_sendmsg( $socket, $last);
}

sub receive_multipart {
    my ($self, $blocking) = @_;
    my $socket = $self->socket;
    my @parts;
    while ( my $rmsg = zmq_recvmsg( $socket, $blocking ? 0 : ZMQ_DONTWAIT)) {
        push (@parts,zmq_msg_data( $rmsg ));
        if (!zmq_getsockopt($socket, ZMQ_RCVMORE)) {
            return \@parts;
        }
    }
}

=method receive_all_multipart_messages

    my $w;$w = AnyEvent->io (
        fh => $fh,
        poll => "r",
        cb => sub {
            my $msgs = receive_multipart_messages($pull);
            foreach (@$msgs) {
                say "got $_";
            }
        },
    );

=cut

sub receive_all_multipart_messages {
    my ($self, $blocking) = @_;
    my $socket = $self->socket;
    my @parts;
    my @msgs;
    while (my $rmsg = zmq_recvmsg( $socket,, $blocking ? 0 : ZMQ_DONTWAIT)) {
        push (@parts,zmq_msg_data( $rmsg ));
        if (! zmq_getsockopt($socket, ZMQ_RCVMORE)) {
            push(@msgs,[ @parts ]);
            undef @parts;
        }
    }
    return \@msgs;
}

1;
