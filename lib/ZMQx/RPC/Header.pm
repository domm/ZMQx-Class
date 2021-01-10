package ZMQx::RPC::Header;

# ABSTRACT: DEPRECATED - A unfinished prototype, do not use
# VERSION

use strict;
use warnings;
use Moose;
use Carp qw(croak);

# TODO specify header position via trait
has 'type' => (is=>'ro',isa=>'Str'); # TODO enum? serializable_types?
has 'timeout' => (is=>'ro',isa=>'Int');

our @header_positions = qw( type timeout );

sub pack {
    my $self = shift;

    my @head;
    foreach my $fld (@header_positions) {
        if (my $v = $self->$fld) {
            push(@head, $v);
        }
        else {
            push(@head, '')
        }
    }
    return join(';',@head);
}

sub unpack {
    my ($class, $packed) = @_;
    my %new;
    my @header = split(/;/,$packed);
    while (my ($index, $val) = each (@header_positions)) {
        next unless defined $header[$index];
        $new{$val} = $header[$index];
    }
    return $class->new(%new);
}

1;

