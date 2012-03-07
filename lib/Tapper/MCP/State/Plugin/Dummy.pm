package Tapper::MCP::State::Plugin::Dummy;

use strict;
use warnings;
use Tapper::MCP::Net::Reset::DoNothing;

use Moose;

has cfg => (is => 'rw',
            isa => 'HashRef',
            default => sub {{}},
           );


sub BUILD{
        my ($self) = @_;
        $self->cfg->{reset_remain} = $self->cfg->{mcp_callback_handler}{pluginoptions}{try_reset} || 0;
}

=head1 NAME

Tapper::MCP::State::Plugin::OSRC - Handle callbacks for MCP states according to OSRC needs

=head1 DESCRIPTION

This is a plugin for Tapper::MCP::State. It offers callback for MCP state changes.


=head1

To use it add the following config to your Tapper config file:

 mcp_callback_handler:
   plugin: DoNothing
   pluginoptions:
     try_reset: 3

This configures Tapper MCP to use the OSRC plugin for state callbacks.

=head1 FUNCTIONS

=head2 keep_alive

Handle keep_alive timeout.

@param Tapper::MCP::State::Details object (for access to state details)

@return success - (0, timeout span)
@return error   - (1, undef)

=cut

sub keep_alive
{
        my ($self, $state_details) = @_;
        if ($self->cfg->{reset_remain} == 0) {
                return (1, undef)
        }
        my $resetter = Tapper::MCP::Net::Reset::DoNothing->new();
        my $options;
        if ($self->cfg->{reset_plugin} eq 'OSRC') {
                $options = $self->cfg->{reset_plugin_options}
        } else {
                $options = $self->cfg->{mcp_callback_handler}{options}{reset_options};
        }
        
        $resetter->reset_host($self->cfg->{hostname}, $options);
        $self->cfg->{reset_remain}--;
        return (0, $self->cfg->{keep_alive}{timeout_receive});
        
}

1;
