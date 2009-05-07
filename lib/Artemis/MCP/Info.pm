package Artemis::MCP::Info;

use Moose;

extends 'Artemis::MCP::Control';

has mcp_info => (is  => 'rw',
                 isa => 'ArrayRef',
                 default => sub {[]},
                );

=head1 NAME

Artemis::MCP::Config - Object for cleaner API of handling mcp_info

=head1 SYNOPSIS

 use Artemis::MCP::Info;

=head1 FUNCTIONS

=cut

=head set_max_reboot

Set number of reboots to be used in a reboot test.

@param int - PRC number
@param int - number of reboots

@return success - 0

=cut

sub set_max_reboot
{
        my ($self, $prc_number, $max_reboot) = @_;
        $self->mcp_info->[$prc_number]->{max_reboot} = $max_reboot;
        return 0;

}


=head get_max_reboot

Get number of reboots to be used in a reboot test for a given PRC number.

@param int - PRC number

@return success - Number of reboots or 0 if not set

=cut

sub get_max_reboot
{
        my ($self, $prc_number) = @_;
        return $self->mcp_info->[$prc_number]->{max_reboot} || 0;
}


=head2 add_prc

Add a PRC with given boot timeout.

@param int - PRC number
@param int - boot timeout

@return success - 0
@return error   - string

=cut

sub add_prc
{
        my ($self, $prc_number, $timeout) = @_;
        return "prc_number not given to add_testprc" if not defined $prc_number;
        $self->mcp_info->[$prc_number]->{timeouts}->{boot} =  $timeout;
        return 0;
}

=head2 add_testprogram

Add a testprogram for a given PRC.

@param int      - PRC number
@param hash ref - config options for program

@return success - 0
@return error   - string

=cut

sub add_testprogram
{
        
        my ($self, $prc_number, $timeout) = @_;
        return "prc_number not given to add_testprogram" if not defined $prc_number;
        push(@{$self->mcp_info->[$prc_number]->{timeouts}->{programs}}, $timeout);
        return 0;
}

=head2 get_testprogram_timeouts

Get all testprogram timeouts for a given PRC.

@param int      - PRC number

@returnlist success - 0

=cut

sub get_testprogram_timeouts
{
        
        my ($self, $prc_number) = @_;
        return unless defined $self->mcp_info->[$prc_number]->{timeouts}->{programs};
        return @{$self->mcp_info->[$prc_number]->{timeouts}->{programs}};
}


=head2 get_prc_count

Get the number of PRCs in this object.

@return number of last PRC

=cut

sub get_prc_count
{
        
        my ($self) = @_;
        return $#{$self->mcp_info};
}




=head get_boot_timeout

Returns the boot timeout for a given PRC

@param int - PRC number

@return success - Boot timeout, undef if not set

=cut

sub get_boot_timeout
{
        my ($self, $prc_number) = @_;
        return $self->mcp_info->[$prc_number]->{timeouts}->{boot};
}

1;

=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Artemis


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 OSRC SysInt Team, all rights reserved.

This program is released under the following license: restrictive
