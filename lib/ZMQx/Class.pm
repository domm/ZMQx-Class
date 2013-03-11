package ZMQx::Class;
use strict;
use warnings;
use 5.010;
use ZMQx::Class::Socket;
use Carp qw(croak carp);

our $VERSION = "0.004";
# ABSTRACT: OO Interface to ZMQ
my $__CONTEXT;

use ZMQ::LibZMQ3 qw(zmq_socket zmq_init);
use ZMQ::Constants qw(ZMQ_REQ ZMQ_REP ZMQ_DEALER ZMQ_ROUTER ZMQ_PULL ZMQ_PUSH ZMQ_PUB ZMQ_SUB  ZMQ_XPUB ZMQ_XSUB ZMQ_PAIR);

my %types = (
    'REQ'=>ZMQ_REQ,
    'REP'=>ZMQ_REP,
    'DEALER'=>ZMQ_DEALER,
    'ROUTER'=>ZMQ_ROUTER,
    'PULL'=>ZMQ_PULL,
    'PUSH'=>ZMQ_PUSH,
    'PUB'=>ZMQ_PUB,
    'SUB'=>ZMQ_SUB,
    'XPUB'=>ZMQ_XPUB,
    'XSUB'=>ZMQ_XSUB,
    'PAIR'=>ZMQ_PAIR,
);

sub new_context {
    my $class = shift;
    return zmq_init();
}

sub context {
    my $class = shift;
    return $__CONTEXT //= $class->new_context(@_);
}

sub socket {
    my $class = shift;
    my $context_or_type = shift;
    my ($context,$type);
    if (ref($context_or_type) eq 'ZMQ::LibZMQ3::Context') {
        $context = $context_or_type;
        $type = shift;
    }
    else {
        $context = $class->context;
        $type = $context_or_type;
    }
    my ($connect, $address, $opts ) = @_;
    croak "no such socket type: $type" unless defined $types{$type};

    my $socket = ZMQx::Class::Socket->new(
        socket => zmq_socket($context,$types{$type}),
        type   => $type,
    );

    if ($opts) {
        while (my ($opt,$val) = each %$opts) {
            my $method = 'set_'.$opt;
            if ($socket->can($method)) {
                $socket->$method($val);
            }
            else {
                carp "no such sockopt $opt";
            }
        }
    }

    if ($connect && $address) {
        if ($connect eq 'bind') {
            $socket->bind($address);
        }
        elsif ($connect eq 'connect') {
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
  use ZMQx::Class::Anyevent;
  
  my $subscriber = ZMQx::Class->socket( 'SUB', connect => 'tcp://localhost:10000' );
  $subscriber->subscribe( '1' );
  
  my $watcher = ZMQx::Class::AnyEvent->watcher( $subscriber, sub {
      while ( my $msg = $subscriber->receive ) {
          say "got $msg->[0] saying $msg->[1]";
      }
  });
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

C<ZMQx::Class> provides an object oriented & Perlish interface to L<ZeroMQ|http://www.zeromq.org/> 3.2. It builds on <ZMQ::LibZMQ3|https://metacpan.org/module/ZMQ::LibZMQ3>.

Before you use C<ZMQx::Class>, please read the excellent <ZeroMQ Guide|http://zguide.zeromq.org>. It's a fun and interesting read, containing everything you need to get started with ZeroMQ, including lots of example code.




