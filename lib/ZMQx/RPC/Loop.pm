package ZMQx::RPC::Loop;
use strict;
use warnings;
use Carp qw(croak);
use Moose::Role;
use AnyEvent;
use Log::Any qw($log);

has '_server_is_running' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

sub loop {
    my ($self, $server) = @_;

    my $running = AnyEvent->condvar;
    my $w;
    my $has_envelope = 0;#
    warn $server->get_type;
    $w = $server->anyevent_watcher(
        sub {
            $running->send unless $self->_server_is_running;

            return unless $server->socket->has_pollin; # Check if this works with a big message / high load
            $log->debugf("i have a poll_in");

            # We have to deal in bytes and do the encoding/decoding ourselves
            # as the envelope section is bytes, not UTF-8-encoded characters.
            while ( my $msg = $server->receive_bytes ) {
                my $envelope = $self->unpack_envelope($msg) if $has_envelope;

                my $res;
                eval {
                    my $req = ZMQx::RPC::Message::Request->unpack($msg);
                    # TODO: handle timeouts using alarm() because AnyEvent won't be interrupted in $cmd
                    my $cmd = $req->command;
                    if ($self->can($cmd)) { # move to hash when implement parametric role
                        my @cmd_res = $self->$cmd(@{$req->payload});

                        $res = $req->new_response(\@cmd_res);
                    }
                    else {
                        $res = $req->new_error_response(400,"no such command $cmd in package ".ref($self));
                    }

                };
                if ($@) {
                    $res = ZMQx::RPC::Message::Response->new_error(500,$@);
                }

                $res->add_envelope($envelope) if $has_envelope;

                $server->send_bytes( $res->pack ); # TODO handle 0mq network errors?
            }
        }
    );

    my $check_running = AnyEvent->timer(
        after    => 0.1,
        interval => 1,
        cb       => sub {
            $running->send unless $self->_server_is_running;
        }
    );

    $running->recv;
    $log->info("Shutting down  instance");
}

sub unpack_envelope {
    my ($self, $msg) = @_;

    # unpack envelope
    my @envelope;
    while ( my $part = shift(@$msg) ) {
        last unless $part;
        push( @envelope, $part );
    }
    push( @envelope, '' );
    return \@envelope;
}

1;
