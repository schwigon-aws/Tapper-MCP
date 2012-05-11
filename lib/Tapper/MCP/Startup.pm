package Tapper::MCP::Startup;
# ABSTRACT: the central "Master Control Program" starter

use 5.010;

use strict;
use warnings;

use Tapper::MCP::Master;
use Moose;

no strict 'refs'; ## no critic (ProhibitNoStrict)

=head1 SYNOPSIS

 use Tapper::MCP::Startup qw(:all);

=head1 FUNCTIONS

=begin method

Declares a method.

=end method

=begin start

Starts all registered daemons.

=end start

=begin stop

Stops all registered daemons.

=end stop

=begin restart

Restarts all registered daemons.

=end restart

=begin status

Prints status of all registered daemons.

=end status

=cut

has master  => (is          => 'rw',
                default     => sub { new Tapper::MCP::Master ( pidfile => '/tmp/tapper_mcp_master.pid' ) }
               );

has servers => ( is         => 'rw',
                 isa        => 'ArrayRef',
                 auto_deref => 1,
                     );

sub start   { my ($self) = @_; $_->start   foreach $self->servers }
sub status  { my ($self) = @_; $_->status  foreach $self->servers }
sub restart { my ($self) = @_; $_->restart foreach $self->servers }
sub stop    { my ($self) = @_; $_->stop    foreach $self->servers }

around 'new' => sub {
                     my ($new, @args) = @_;

                     my $self = $new->(@args);
                     $self->set_servers;
                     return $self;
                    };

=begin set_servers

Registers all handled daemons in an array.

=end set_servers

=cut

sub set_servers
{
        my ($self) = @_; 
        $self->servers ([
                         $self->master,
                        ]);
}

=begin run

Dispatches the commandline command (start, stop, restart, status) to
all its daemons.

=end run

=cut

sub run
{
        my ($self) = @_; 
        my ($command) = @ARGV;
        return unless $command && grep /^$command$/, qw(start status restart stop);
        local @ARGV;   # cleaner approach than changing @ARGV
        $self->$command;
}

1;
