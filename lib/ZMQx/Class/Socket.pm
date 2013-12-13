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

# TODO
# has 'bind_or_connect',
# has 'address',

has '_init_opts_for_cloning' =>
    ( is => 'ro', isa => "ArrayRef", default => sub { [] } );

has '_socket' => (
    is       => 'rw',
    isa      => 'ZMQ::LibZMQ3::Socket',
    required => 1,
);

has 'type' => (
    is       => 'ro',
    required => 1,
);

has '_connected' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has '_pid' => ( is => 'rw', isa => 'Int', required => 1 );

=method socket

    $socket->socket;

Returns the underlying C<ZMQ::LibZMQ3::Socket> socket. You probably won't need to call this method yourself.

When a process containg a socket is forked, a new instance of the socket will be set up for the child process.

=cut

sub socket {
    my ($self) = @_;
    if ( $$ != $self->_pid ) {
        # TODO instead of init_opts_for_cloning get stuff required to re-initate via getsockopt etc
        my ( $class, @call ) = @{ $self->_init_opts_for_cloning };
        my $socket = $class->socket(@call);

        $self->_socket( $socket->socket );
        $self->_pid( $socket->_pid );
    }
    return $self->_socket;
}

=method

    $socket->bind( $address );

Bind a socket to an address. Use this for the "server" side, which usually is the more stable part of your infrastructure.

C<bind> will C<die> if it cannot bind.

=cut

sub bind {
    my ( $self, $address ) = @_;
    my $rv = zmq_bind( $self->socket, $address );
    if ( $rv == -1 ) {
        croak "Cannot bind: $!";
    }
    $self->_connected(1);
}

=method connect

    $socket->connect( $address );

Connect the socket to an address. Use this for the "client" side.

C<connect> will C<die> if it cannot connect.

=cut

sub connect {
    my ( $self, $address ) = @_;
    my $rv = zmq_connect( $self->socket, $address );
    if ( $rv == -1 ) {
        croak "Cannot connect: $!";
    }
    $self->_connected(1);
}

=method setsockopt

    use ZMQ::Constants qw( ZMQ_LINGER );
    $socket->setsockopt( ZMQ_LINGER, 100 );

Set a socket options using a constant. You will need to load the constant from C<ZMQ::Constants>.

=cut

sub setsockopt {
    my $self = shift;
    zmq_setsockopt( $self->socket, @_ );
}

=method getsockopt

    use ZMQ::Constants qw( ZMQ_LINGER );
    $socket->getsockopt( ZMQ_LINGER );

Get a socket option value using a constant. You will need to load the constant from C<ZMQ::Constants>.

=cut

sub getsockopt {
    my $self = shift;
    zmq_getsockopt( $self->socket, @_ );
}

=method send

    my $rv = $socket->send( \@message );
    my $rv = $socket->send( \@message, ZMQ_DONTWAIT );
    my $rv = $socket->send( $message );

Send a message over the socket.

The message can either be a plain string or an ARRAYREF which will be
send as a multipart message (with one message per array element).
C<send> will automatically set C<ZMQ_SENDMORE> for multipart messages.

You can pass flags to C<send>. Currently the only flag is C<ZMQ_DONTWAIT>.

C<send> returns the number of bytes send in the last message (TODO this should be changes to the total number of bytes for the whole multipart message), or -1 on error.

=cut

sub send {
    my ( $self, $parts, $flags ) = @_;
    $flags //= 0;

    if ( !ref($parts) ) {
        $parts = [$parts];
    }
    my $max_idx = $#{$parts};
    my $socket  = $self->socket;
    if ( $max_idx == 0 ) {    # single part message
        return zmq_msg_send( $parts->[0], $socket, $flags );
    }

    # multipart
    my $mflags = $flags ? $flags | ZMQ_SNDMORE : ZMQ_SNDMORE;
    foreach ( 0 .. $max_idx - 1 ) {
        my $rv = zmq_msg_send( $parts->[$_], $socket, $mflags );
        #warn "send $rv $!";
        return $rv if $rv == -1;
    }
    my $rv = zmq_msg_send( $parts->[$max_idx], $socket, $flags );
    return $rv;
}

sub receive_multipart {
    my $rv = receive(@_);
    carp 'DEPRECATED! Use $socket->receive() instead';
    *{receive_multipart} = *{receive} unless $ENV{HARNESS_ACTIVE};
    return $rv;
}

=method receive

    my $msg = $socket->receive;
    my $msg = $socket->receive('blocking;);

C<receive> will get the next message from the socket, if there is one.

You can use the blocking mode (by passing a true value to C<receive>) to block the process until a message has been received (NOT a wise move if you are connected to a lot of clients! Use AnyEvent in this case)

The message will always be a ARRAYREF containing one element per message part.

Returns C<undef> if no message can be received.

See t/30_anyevent.t for some examples

=cut

sub receive {
    my ( $self, $blocking ) = @_;
    my $socket = $self->socket;
    my @parts;
    while (1) {
        my $msg = zmq_msg_init();
        my $rv = zmq_msg_recv( $msg, $socket, $blocking ? 0 : ZMQ_DONTWAIT );
        return if $rv == -1;
        #warn "receive rv $rv $!";
        push( @parts, zmq_msg_data($msg) );
        if ( !zmq_getsockopt( $socket, ZMQ_RCVMORE ) ) {
            last;
        }
    }
    if (@parts) {
        return \@parts;
    }
    return;
}

sub subscribe {
    my ( $self, $subscribe ) = @_;
    croak('$socket->subscribe only works on SUB sockets')
        unless $self->type =~ /^X?SUB$/;
    croak('required parameter $subscription missing')
        unless defined $subscribe;
    zmq_setsockopt( $self->socket, ZMQ_SUBSCRIBE, $subscribe );
}

sub get_fh {
    carp 'DEPRECATED! Use $socket->get_fd() instead';
    my $rv = get_fd(@_);
    *{get_fh} = *{get_fd};
    return $rv;
}

sub get_fd {
    my $self = shift;
    return zmq_getsockopt( $self->socket, ZMQ_FD );
}

{
    no strict 'refs';
    my @sockopts_before_connect
        = qw(ZMQ_SNDHWM ZMQ_RCVHWM ZMQ_AFFINITY ZMQ_IDENTITY ZMQ_RATE ZMQ_RECOVERY_IVL ZMQ_SNDBUF ZMQ_RCVBUF ZMQ_RECONNECT_IVL ZMQ_RECONNECT_IVL_MAX ZMQ_BACKLOG ZMQ_MAXMSGSIZE ZMQ_MULTICAST_HOPS ZMQ_RCVTIMEO ZMQ_SNDTIMEO ZMQ_IPV4ONLY ZMQ_EVENTS ZMQ_LAST_ENDPOINT);

    my @sockopts_after_connect
        = qw(ZMQ_SUBSCRIBE ZMQ_UNSUBSCRIBE ZMQ_LINGER ZMQ_ROUTER_MANDATORY ZMQ_XPUB_VERBOSE);

    my $stash = Package::Stash->new(__PACKAGE__);
    foreach my $const (@sockopts_before_connect) {
        _setup_sockopt_helpers( $const, $stash, 1 );
    }
    foreach my $const (@sockopts_after_connect) {
        _setup_sockopt_helpers( $const, $stash, 0 );
    }

}

sub _setup_sockopt_helpers {
    my ( $const, $stash, $set_only_before_connect ) = @_;
    my $get = my $set = lc($const);
    $set =~ s/^zmq_/set_/;
    $get =~ s/^zmq_/get_/;
    no strict 'refs';

    if ( $stash->has_symbol( '&' . $const ) ) {
        my $constval = &$const;
        if ($set_only_before_connect) {
            $stash->add_symbol(
                '&' . $set => sub {
                    my $self = shift;
                    if ( $self->_connected ) {
                        carp
                            "Setting '$const' only works before connect/bind. Value not stored!";
                    }
                    else {
                        zmq_setsockopt( $self->socket, $constval, @_ );
                    }
                    return $self;
                } );
        }
        else {
            $stash->add_symbol(
                '&' . $set => sub {
                    my $self = shift;
                    zmq_setsockopt( $self->socket, $constval, @_ );
                    return $self;
                } );
        }
        $stash->add_symbol(
            '&' . $get => sub {
                my $self = shift;
                return zmq_getsockopt( $self->socket, $constval );
            } );
    }
}

=method anyevent_watcher

  my $watcher = $socket->anyevent_watcher( sub {
      while (my $msg = $socket->receive) {
          # do something with msg
      }
  } );

Set up an AnyEvent watcher that will call the passed sub when a new
incoming message is received on the socket.

Note that the C<$socket> object isn't passed to the callback. You can only access the C<$socket> thanks to closures.

Please note that you will have to load C<AnyEvent> in your code!

=cut

sub anyevent_watcher {
    my ( $socket, $callback ) = @_;
    my $fd      = $socket->get_fd;
    my $watcher = AnyEvent->io(
        fh   => $fd,
        poll => "r",
        cb   => $callback
    );
    return $watcher;
}

sub close {
    my $self = shift;
    warn "$$ CLOSE SOCKET";
    zmq_close($self->_socket);

}
#
#sub DESTROY {
#    my $self = shift;
#    warn "$$ IN SOCKET DESTROY";
#    zmq_close($self->_socket);
#}

1;
