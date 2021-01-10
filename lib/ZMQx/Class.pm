package ZMQx::Class;

# ABSTRACT: DEPRECATED - OO Interface to ZMQ
# VERSION

warn __PACKAGE__ .' is DEPRECATED, please do not use this module anymore';

use strict;
use warnings;
use 5.010;
use ZMQx::Class::Socket;
use Carp qw(croak carp);

my $__CONTEXT = {};

use ZMQ::FFI;
use ZMQ::Constants qw(
    ZMQ_DEALER
    ZMQ_PAIR
    ZMQ_PUB
    ZMQ_PULL
    ZMQ_PUSH
    ZMQ_REP
    ZMQ_REQ
    ZMQ_ROUTER
    ZMQ_SUB
    ZMQ_XPUB
    ZMQ_XSUB
);

my %types = (
    'REQ'    => ZMQ_REQ,
    'REP'    => ZMQ_REP,
    'DEALER' => ZMQ_DEALER,
    'ROUTER' => ZMQ_ROUTER,
    'PULL'   => ZMQ_PULL,
    'PUSH'   => ZMQ_PUSH,
    'PUB'    => ZMQ_PUB,
    'SUB'    => ZMQ_SUB,
    'XPUB'   => ZMQ_XPUB,
    'XSUB'   => ZMQ_XSUB,
    'PAIR'   => ZMQ_PAIR,
);

sub _new_context {
    my $class = shift;
    return ZMQ::FFI->new( @_ );
}

=method context

    my $ctx = ZMQx::Class->context;

Return the current context for this process.

ZMQx::Class pools one context per process (pid). It will always use the currents process socket, and set up a new context after a fork. This should be very helpful for most use cases (e.g. when you need a 0mq socket inside a preforked webapp).

If you want to get a new context, use C<< ZMQx::Class->_new_context >>. But you will have to manage this context yourself!

=cut

sub context {
    my $class = shift;
    return $__CONTEXT->{$$} //= $class->_new_context(@_);
}

=method socket

    my $socket = ZMQx::Class->socket( $type );
    my $socket = ZMQx::Class->socket( $type, bind => $endpoint );
    my $socket = ZMQx::Class->socket( $type, connect => $endpoint, \%opts );
    my $socket = ZMQx::Class->socket( $context, $type );

C<socket> is a factory method that returns a new C<ZMQx::Class::Socket> object. The new socket will use the default process-wide context.

    my $socket = ZMQx::Class->socket( $type );

Returns a new socket of the given type. Types are valid 0mq sockets:

    REQ REP DEALER ROUTER PULL PUSH PUB SUB XPUB XSUB PAIR

This socket will be neither bound nor connected, and have no sockopts set.

B<connect / bind>

    my $socket = ZMQx::Class->socket( $type, [bind | connect] => $endpoint );

If you call socket like this, you will get back a socket that's already bound or connected to the given endpoint.

B<options>

    my $socket = ZMQx::Class->socket( $type, connect => $endpoint, {
        sndhwm  => 500
    });

You can pass in a hashref containing valid sockopts to set them before connect/bind. A lot of sockopts can only be set before connect/bind, so if you want to set them, either pass them to C<socket>, or do not use the autoconnect/bind feater.

See Sockopts in ZMQx::Class::Socket for a list of valid options.

B<context>

If you really need to, you can pass a context object as the first agrument to C<socket>.

    my $socket = ZMQx::Class->socket( $context, $type );

=cut

sub socket {
    my $class           = shift;
    my $context_or_type = shift;
    my ( $context, $type );
    if ( ref($context_or_type) =~ /^ZMQ::FFI::ZMQ\d::Context/ ) {
        $context = $context_or_type;
        $type    = shift;
    }
    else {
        $context = $class->context;
        $type    = $context_or_type;
    }
    my ( $connect, $address, $opts ) = @_;
    croak "no such socket type: $type" unless defined $types{$type};

    my $socket = ZMQx::Class::Socket->new(
        _socket => $context->socket( $types{$type} ),
        type    => $type,
        _pid    => $$,
        _init_opts_for_cloning => [ $class, $type, @_ ],
    );

    if ($opts) {
        while ( my ( $opt, $val ) = each %$opts ) {
            my $method = 'set_' . $opt;
            if ( $socket->can($method) ) {
                $socket->$method($val);
            }
            else {
                carp "no such sockopt $opt";
            }
        }
    }

    if ( $connect && $address ) {
        if ( $connect eq 'bind' ) {
            $socket->bind($address);
        }
        elsif ( $connect eq 'connect' ) {
            $socket->connect($address);
        }
        else {
            croak "no such connect type: $connect";
        }
    }
    return $socket;
}

q{ listening to: Tosca - Odeon };

__END__

=head1 SYNOPSIS

DEPRECATED - This was only a prototype and never used in production. I doubt it still works with current zmq.

  # a ZeroMQ publisher
  # see example/publisher.pl
  use ZMQx::Class;
  my $publisher = ZMQx::Class->socket( 'PUB', bind => 'tcp://*:10000' );

  while ( 1 ) {
      my $random = int( rand ( 10_000 ) );
      say "sending $random hello";
      $publisher->send( [ $random, 'hello' ] );
      select( undef, undef, undef, 0.1);
  }


  # a ZeroMQ subscriber
  # see example/subscriber.pl
  use ZMQx::Class;
  use Anyevent;

  my $subscriber = ZMQx::Class->socket( 'SUB', connect => 'tcp://localhost:10000' );
  $subscriber->subscribe( '1' );

  my $watcher = $subscriber->anyevent_watcher( sub {
      while ( my $msg = $subscriber->receive ) {
          say "got $msg->[0] saying $msg->[1]";
      }
  });
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

DEPRECATED - This was only a prototype and never used in production. I doubt it still works with current zmq. But here are the old docs:

C<ZMQx::Class> provides an object oriented & Perlish interface to L<ZeroMQ|http://www.zeromq.org/> 3.2. It builds on L<ZMQ::FFI|https://metacpan.org/module/ZMQ::FFI>.

Before you use C<ZMQx::Class>, please read the excellent <ZeroMQ Guide|http://zguide.zeromq.org>. It's a fun and interesting read, containing everything you need to get started with ZeroMQ, including lots of example code.

=head1 SEE ALSO

L<ZMQ|https://metacpan.org/module/ZMQ::Socket> is another perlish interface to libzmq. We found it to still be a bit too low-level (eg, you still need to import the sockopt-constants). ZMQ support libzmq 2 and 3, and promises a single interface to both. We are only interested in libzmq 3. ZMQx::Class includes some smartness to handle setup of context objects, even across forks. Lastly, we found this note from the docs not very promising: "Personally, I'd recommend only using this module for your one-shot scripts, and use ZMQ::LibZMQ* for all other uses."

=head1 THANKS

Thanks to L<Validad|http://www.validad.com/> for sponsoring the development of this module.

