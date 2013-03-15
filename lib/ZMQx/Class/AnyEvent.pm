package ZMQx::Class::AnyEvent;
use strict;
use warnings;
use 5.010;

# ABSTRACT: AnyEvent helpers

use AnyEvent;

sub watcher {
    my ($class, $socket, $callback) = @_;
    my $fd = $socket->get_fd;
    my $watcher = AnyEvent->io (
        fh      => $fd,
        poll    => "r",
        cb      => $callback
    );
    return $watcher;
}

1;
