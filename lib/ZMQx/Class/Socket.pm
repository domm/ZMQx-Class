package ZMQx::Class::Socket;
use strict;
use warnings;
use 5.010;

# ABSTRACT: A ZMQ Socket

use Moose;
use Carp qw(croak carp);
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

has '_connected' => (
    is=>'rw',
    isa=>'Bool',
    default=>0,
);

sub bind {
    my ($self, $address) = @_;
    zmq_bind($self->socket,$address);
    $self->_connected(1);
}

sub connect {
    my ($self, $address) = @_;
    zmq_connect($self->socket,$address);
    $self->_connected(1);
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
    my ($self, $parts, $flags) = @_;
    $flags //= 0;

    my $max_idx = $#{$parts};
    if ($max_idx == 0) { # single part message
        return zmq_msg_send($parts->[0], $self->socket, $flags);
    }

    # multipart
    my $socket = $self->socket;
    my $mflags = $flags ? $flags | ZMQ_SNDMORE : ZMQ_SNDMORE;
    foreach (0 .. $max_idx - 1) {
        zmq_msg_send( $parts->[$_], $socket, $mflags);
    }
    zmq_msg_send( $parts->[$max_idx], $socket, $flags);
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
    my @sockopts_before_connect = qw(ZMQ_SNDHWM ZMQ_RCVHWM ZMQ_AFFINITY ZMQ_IDENTITY ZMQ_RATE ZMQ_RECOVERY_IVL ZMQ_SNDBUF ZMQ_RCVBUF ZMQ_RECONNECT_IVL ZMQ_RECONNECT_IVL_MAX ZMQ_BACKLOG ZMQ_MAXMSGSIZE ZMQ_MULTICAST_HOPS ZMQ_RCVTIMEO ZMQ_SNDTIMEO ZMQ_IPV4ONLY);

    my @sockopts_after_connect = qw(ZMQ_SUBSCRIBE ZMQ_UNSUBSCRIBE ZMQ_LINGER ZMQ_ROUTER_MANDATORY ZMQ_XPUB_VERBOSE);

    my $stash = Package::Stash->new(__PACKAGE__);
    foreach my $const (@sockopts_before_connect) {
        _setup_sockopt_helpers($const, $stash, 1);
    }
    foreach my $const (@sockopts_after_connect) {
        _setup_sockopt_helpers($const, $stash, 0);
    }

}

sub _setup_sockopt_helpers {
    my ($const, $stash, $set_only_before_connect) = @_;
    my $get = my $set = lc($const);
    $set =~s/^zmq_/set_/;
    $get =~s/^zmq_/get_/;
    no strict 'refs';

    if ($stash->has_symbol('&'.$const)) {
        my $constval = &$const;
        if ($set_only_before_connect) {
            $stash->add_symbol('&'.$set => sub {
                my $self = shift;
                if ($self->_connected) {
                    carp "Setting '$const' only works before connect/bind. Value not stored!";
                }
                else {
                    zmq_setsockopt($self->socket,$constval,@_);
                }
                return $self;
            });
        }
        else {
            $stash->add_symbol('&'.$set => sub {
                my $self = shift;
                zmq_setsockopt($self->socket,$constval,@_);
                return $self;
            });
        }
        $stash->add_symbol('&'.$get => sub {
            my $self = shift;
            return zmq_getsockopt($self->socket,$constval);
        });
    }
}

1;
