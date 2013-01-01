package ZMQx::Class::AnyEvent;
use strict;
use warnings;
use 5.010;

use AnyEvent;

sub watcher {
    my ($class, $socket, $callback) = @_;
    my $fh = $socket->get_fh;
    my $watcher = AnyEvent->io (
        fh      => $fh,
        poll    => "r",
        cb      => $callback
    );
    return $watcher;
}

1;
