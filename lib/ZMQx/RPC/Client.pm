package ZMQx::RPC::Client;
use strict;
use warnings;
use Log::Any qw($log);
use Carp qw(croak carp);

use vars qw(@EXPORT_OK);
use parent 'Exporter';

@EXPORT_OK = qw(rpc_bind);

sub rpc_bind {
    # Mandatory are:
    # server
    #     an object that quacks like ZMQ::Class::Socket, or a function to call
    #     that returns one.
    # command
    #     name of the command to call.
    # Optional:
    # on_error
    #     A callback to handle errors. Assumed to throw, or to return a default.
    # server_name:
    #     A descriptive name for the server to use in log messages.
    my %args = (
                # Default parameter type. Maybe this should be JSON
                type => 'string',
                # Default return type. Also valid Item and List
                return => 'ArrayRef',
                @_);
    my ($command, $server, $type, $on_error)
        = @args{qw(command server type on_error)};
    croak('command is a mandatory argument')
        unless length $command;
    croak('server is a mandatory argument')
        unless ref $server;
    my $server_name = $args{server_name} // 'server';

    return sub {
        my $socket = 'CODE' eq ref $server ? &$server(@_) : $server;
        carp("No $server_name for $command")
            unless ref $socket;

        my $msg = ZMQx::RPC::Message::Request->new(command => $command,
                                                   type => $type,
                                                  );

        my $response;
        eval {
            # We're actually a closure, not a method.
            # This probably needs to be "fixed" to be general.
            $socket->send_bytes($msg->pack(@_[1..$#_]));

            $log->debugf("Sent message >%.40s< to $server", join(",", $command, @_));
            my $raw = $socket->receive_bytes(1);
            die "no response from $server for $command"
                unless $raw;
            $response = ZMQx::RPC::Message::Response->unpack($raw);
            die "failed to unpack response from $server for $command"
                unless $response;
            die $response->payload->[0]
                unless $response->status == 200;
        };
        if ($@) {
            return &$on_error($@, \@_, $msg, $response, \%args)
                if $on_error;
            $log->error($@);
            croak $@;
        }
        return $response->payload;
    };
}

1;
