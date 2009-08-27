package Artemis::MCP::Info;

use Moose;

extends 'Artemis::MCP';

has mcp_info => (is  => 'rw',
                 isa => 'HashRef',
                 default => sub {{}},
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
        $self->mcp_info->{prc}->[$prc_number]->{max_reboot} = $max_reboot;
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
        return $self->mcp_info->{prc}->[$prc_number]->{max_reboot} || 0;
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
        $self->mcp_info->{prc}->[$prc_number]->{timeouts}->{boot} =  $timeout;
        return 0;
}

=head2 add_testprogram

Add a testprogram for a given PRC. The given config has should have the
following elements:
program             - string - full path of the test program
timeout             - int    - timeout value for the test program
timeout_testprogram - int    - timeout value for the test program (deprecated)
parameters - array of string - parameter array as given to exec



@param int      - PRC number
@param hash ref - config options for program

@return success - 0
@return error   - string

=cut

sub add_testprogram
{

        my ($self, $prc_number, $program) = @_;
        return "prc_number not given to add_testprogram" if not defined $prc_number;
        $program->{timeout} = $program->{timeout_testprogram} || $program->{timeout} || 0;
        push(@{$self->mcp_info->{prc}->[$prc_number]->{programs}}, $program);
        push(@{$self->mcp_info->{prc}->[$prc_number]->{timeouts}->{programs}}, $program->{timeout});
        return 0;
}

=head2 get_testprogram_timeouts

Get all testprogram timeouts for a given PRC.

@param int          - PRC number

@returnlist success - array of ints

=cut

# This function exists forconvenience in timeout handling. The same could be
# achieved with get_testprogam and reading timeout values of every element
# returned. (This comment is not part of pod to prevent it from becoming part
# of the external documentation.
sub get_testprogram_timeouts
{


        my ($self, $prc_number) = @_;
        return unless defined $self->mcp_info->{prc}->[$prc_number]->{timeouts}->{programs};
        return @{$self->mcp_info->{prc}->[$prc_number]->{timeouts}->{programs}};
}

=head2 get_testprograms

Get all testprograms  for a given PRC.

@param int      - PRC number

@returnlist success - 0

=cut

sub get_testprograms
{

        my ($self, $prc_number) = @_;
        return unless defined $self->mcp_info->{prc}->[$prc_number]->{programs};
        return @{$self->mcp_info->{prc}->[$prc_number]->{programs}};
}



=head2 get_prc_count

Get the number of PRCs in this object.

@return number of last PRC

=cut

sub get_prc_count
{

        my ($self) = @_;
        return $#{$self->mcp_info->{prc}};
}




=head get_boot_timeout

Returns the boot timeout for a given PRC

@param int - PRC number

@return success - Boot timeout, undef if not set

=cut

sub get_boot_timeout
{
        my ($self, $prc_number) = @_;
        return $self->mcp_info->{prc}->[$prc_number]->{timeouts}->{boot};
}

=head set_installer_timeout

Setter for installer timeout.

@param int - Timeout value

@return success - 0

=cut

sub set_installer_timeout
{
        my ($self, $timeout) = @_;
        $self->mcp_info->{installer}{timeouts} = $timeout;
        return 0;
}

=head get_installer_timeout

Getter for installer timeout.

@return success - Timeout value

=cut

sub get_installer_timeout
{
        my ($self) = @_;
        return $self->mcp_info->{installer}{timeouts} || 0;
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
