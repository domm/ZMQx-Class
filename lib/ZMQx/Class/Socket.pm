package ZMQx::Class::Socket;
use strict;
use warnings;
use 5.010;

# ABSTRACT: A ZMQ Socket

use Moose;
use Carp qw(croak);
use namespace::autoclean;
use Package::Stash;
use ZMQ::LibZMQ3;

use ZMQ::Constants ':all';

has 'socket' => (
    is=>'ro',
    isa=>'ZMQ::LibZMQ3::Socket',
    required=>1,
);

has 'type' => (
    is=>'ro',
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

sub getsockopt {
    my $self = shift;
    zmq_getsockopt($self->socket, @_);
}

sub send {
    my ($self, $msg) = @_;
    zmq_msg_send($msg, $self->socket);
}

sub send_multipart {
    my ($self, @parts) = @_;
    my $socket = $self->socket;
    my $last = pop(@parts);
    foreach (@parts) {
        zmq_msg_send( $_, $socket, ZMQ_SNDMORE );
    }
    zmq_msg_send($last, $socket );
}

sub send_dontwait {
    my ($self, @parts) = @_;
    my $socket = $self->socket;
    my $last = pop(@parts);
    foreach (@parts) {
        zmq_msg_send($_, $socket, ZMQ_SNDMORE | ZMQ_DONTWAIT );
    }
    zmq_msg_send( $last, $socket, ZMQ_DONTWAIT);
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
    while (my $rmsg = zmq_recvmsg( $socket, $blocking ? 0 : ZMQ_DONTWAIT)) {
        push (@parts,zmq_msg_data( $rmsg ));
        if (! zmq_getsockopt($socket, ZMQ_RCVMORE)) {
            push(@msgs,[ @parts ]);
            undef @parts;
        }
    }
    return \@msgs;
}

sub wait_for_message {
    my $socket = shift;
    my $msg;
    my $got_message = AnyEvent->condvar;
    my $fh = $socket->get_fh;
    my $watcher = AnyEvent->io (
        fh      => $fh,
        poll    => "r",
        cb      => sub {
            $msg = $socket->receive_multipart;
            $got_message->send;
        },
    );
    $got_message->recv;
    return $msg;
}

sub subscribe {
    my ($self, $subscribe) = @_;
    croak('$socket->subscribe only works on SUB sockets') unless $self->type =~/^X?SUB$/;
    croak('required paramater $subscription missing') unless defined $subscribe;
    zmq_setsockopt($self->socket,ZMQ_SUBSCRIBE,$subscribe);
}

sub get_fh {
    my $self = shift;
    return zmq_getsockopt($self->socket, ZMQ_FD);
}

{
    no strict 'refs';
    my @sockopt_constants=qw(ZMQ_SNDHWM ZMQ_RCVHWM ZMQ_AFFINITY ZMQ_SUBSCRIBE ZMQ_UNSUBSCRIBE ZMQ_IDENTITY ZMQ_RATE ZMQ_RECOVERY_IVL ZMQ_SNDBUF ZMQ_RCVBUF ZMQ_LINGER ZMQ_RECONNECT_IVL ZMQ_RECONNECT_IVL_MAX ZMQ_BACKLOG ZMQ_MAXMSGSIZE ZMQ_MULTICAST_HOPS ZMQ_RCVTIMEO ZMQ_SNDTIMEO ZMQ_IPV4ONLY);
    my $stash = Package::Stash->new(__PACKAGE__);
    foreach my $const (@sockopt_constants) {
        my $method = lc($const);
        $method =~s/^zmq_/set_/;

        if ($stash->has_symbol('&'.$const)) {
            my $constval = &$const;
            $stash->add_symbol('&'.$method => sub {
                my $self = shift;
                zmq_setsockopt($self->socket,$constval,@_);
                return $self;
            });
        }
    }
}
1;
