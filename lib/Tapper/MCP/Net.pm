package Tapper::MCP::Net;

use strict;
use warnings;

use 5.010;

use Moose;
use Socket;
use Net::SSH;
use Net::SSH::Expect;
use IO::Socket::INET;
use Sys::Hostname;
use File::Basename;
use YAML;

extends 'Tapper::MCP';

use Tapper::Model qw(model get_hardware_overview);

=head2 conserver_connect

This function opens a connection to the conserver. Conserver, port and user
can be given as arguments, yet are optional.
@param string - system to open a console to
@opt   string - Address or name of the console server
@opt   int    - port number of the console server
@opt   string - username to be used


@returnlist success - (IO::Socket::INET object)
@returnlist error   - (error string)

=cut

sub conserver_connect
{
        my ($self, $system, $conserver, $conserver_port, $conuser) = @_;
        $conserver      ||= $self->cfg->{conserver}{server};
        $conserver_port ||= $self->cfg->{conserver}{port};
        $conuser        ||= $self->cfg->{conserver}{user};

        my $sock = IO::Socket::INET->new(PeerPort => $conserver_port,
                                         PeerAddr => $conserver,
                                         Proto    => 'tcp');

        return ("Can't open connection:$!") unless $sock;
        my $data=<$sock>; return($data) unless $data=~/^ok/;

        print $sock "login $conuser\n";
        $data=<$sock>; return($data) unless $data=~/^ok/;

        print $sock "call $system\n";
        my $port=<$sock>;
        if ($port=~ /@(\w+)/) {
                return $self->conserver_connect ($system,$1,$conserver_port,$conuser);
        } else {
                return($port) unless $port=~/^\d+/;
        }


        print $sock "exit\n";
        $data=<$sock>; return($data) unless $data=~/^goodbye/;
        close $sock;

        $sock = IO::Socket::INET->new(PeerPort => int($port),
                                      PeerAddr => $conserver,
                                      Proto    => 'tcp');
        return ("Can't open connection to $conserver:$!") unless $sock;


        $data=<$sock>;return($data) unless $data=~/^ok/;
        print $sock "login $conuser\n";
        $data=<$sock>;return($data) unless $data=~/^ok/;
        print $sock "call $system\n";
        $data=<$sock>;return($data) unless $data=~/^(\[attached\]|\[spy\])/;

        print ($sock "\005c;\n");  # console needs to be "activated"
        $data=<$sock>;return($data) unless $data=~/^(\[connected\])/;
        return($sock);
}

=head2 conserver_disconnect

Disconnect the filehandle given as first argument from the conserver.
We first try to quit kindly but if this fails (by what reason ever)
the filehandle is simply closed. Closing a socket can not fail, so the
function always succeeds. Thus no return value is needed.

@param  IO::Socket::INET - file handle connected to the conserver

@return none

=cut

sub conserver_disconnect
{
        my ($self, $sock) = @_;
        if ($sock) {
                eval {
                        local $SIG{ALRM} = sub { die 'Timeout'; };
                        alarm (2);
                        if ($sock->can("connected") and $sock->connected()) {
                                print ($sock "\005c.\n");
                                <$sock>; # ignore return value, since we close the socket anyway
                        }
                };
                alarm (2);
                $sock->close() if $sock->can("close");
        }
}


=head2 start_simnow

Start a simnow installation on given host. Installer is supposed to
start the simnow controller in turn.

@param string - hostname

@return success - 0
@return error   - error string

=cut

sub start_simnow
{
        my ($self, $hostname) = @_;

        my $simnow_installer = $self->cfg->{files}{simnow_installer};
        my $server = Sys::Hostname::hostname() || $self->cfg->{mcp_host};
        my $retval = Net::SSH::ssh("root\@$hostname",$simnow_installer, "--host=$server");
        return "Can not start simnow installer: $!" if $retval;


        $self->log->info("Simnow installation started on $hostname.");
        return 0;

}


=head2 reboot_system

Reboot the named system. First we try to do it softly, if that does not
work, we try a hard reboot. Unfortunately this does not give any
feedback. Thus you have to wait for the typical reboot time of the
system in question and if the system does not react after this time
assume that the reboot failed. This is not included in this function,
since it would make it to complex.

@param string - name of the system to be rebooted
@param bool   - hard reset without ssh

@return success - 0
@return error   - error string

=cut

sub reboot_system
{
        my ($self, $host, $hard) = @_;
	$self->log->debug("Trying to reboot $host.");

        ## Some machines do not boot up correctly after a shutdown with
        ## ssh and reboot (e.g. because they do not even shut down correctly
        ## waiting for services like NFS to shut down).
        if (not $hard) {
                $self->log->info("Try reboot via Net::SSH::Expect"); # usually for the installed host/dom0 system
                my $ssh = new Net::SSH::Expect( host     => $host,
                                                password => 'xyzxyz',
                                                user     => 'root',
                                                raw_pty  => 1 );
                my $output;
                # Try login, with timeout
                eval {
                        local $SIG{ALRM} = sub{ die("timeout in login") };
                        alarm(10);
                        my $login_output = $ssh->login();

                        if ($login_output)
                        {
                                $self->log->info("Logged in. Try exec reboot");
                                $ssh->exec("stty raw -echo");
                                $output = $ssh->exec("reboot");
                        }
                };
                alarm(0);
                if ($output and $output =~ 'The system is going down for reboot') {
                        return 0;
                } elsif ($@) {
                        $self->log->error("Can not reboot $host with SSH: $@");
                } else {
                        $self->log->error("Can not reboot $host with SSH: $output");
                }
        }

        # else trigger reset switch

        my $reset_plugin         = $self->cfg->{reset_plugin};
        my $reset_plugin_options = $self->cfg->{reset_plugin_options};

        my $reset_class = "Tapper::MCP::Net::Reset::$reset_plugin";
        eval "use $reset_class"; ## no critic

        if ($@) {
                return "Could not load $reset_class";
        } else {
                no strict 'refs'; ## no critic
                $self->log->info("Call ${reset_class}::reset_host($host)");
                my ($error, $retval) = &{"${reset_class}::reset_host"}($self, $host, $reset_plugin_options);
                if ($error) {
                        $self->log->error("Error occured: ".$retval);
                        return $retval;
                }
                return 0;
        }
}


=head2 write_grub_file

Write a grub file for the system given as parameter. An optional second
parameter containing the text to be put into the grub file can be used. If
this parameter is not defined or empty a default value is used.

@param string - name of the system
@param string - text to put into grub file; optional


@return success - 0
@return error   - error string

=cut

sub write_grub_file
{
        my ($self, $system, $text) = @_;
        my $tapper_host = Sys::Hostname::hostname();
        my $tapper_ip   = gethostbyname($tapper_host);
        return qq{Can not find IP address of "$tapper_host".} if not $tapper_ip;
        $tapper_ip = inet_ntoa($tapper_ip);

        my $grub_file    = $self->cfg->{paths}{grubpath}."/$system.lst";

	$self->log->debug("writing grub file ($tapper_host, $grub_file)");

	# create the initial grub file for installation of the test system,
	open (my $GRUBFILE, ">", $grub_file) or return "Can open ".$self->cfg->{paths}{grubpath}."/$system.lst for writing: $!";

        my $tftp_server = $self->cfg->{tftp_server_address};
        my $kernel = $self->cfg->{files}{installer_kernel};
        my $nfsroot = $self->cfg->{paths}{nfsroot};
	if (not $text) {
                $text = <<END;
serial --unit=0 --speed=115200
terminal serial

default 0
timeout 2

title Test
     tftpserver $tftp_server
     kernel $kernel earlyprintk=serial,ttyS0,115200 console=ttyS0,115200 root=/dev/nfs ro ip=dhcp nfsroot=$nfsroot tapper_host=$tapper_host tapper_ip=$tapper_ip
END
        }
	print $GRUBFILE $text;
	close $GRUBFILE or return "Can't save grub file for $system:$!";
	return(0);
}


=head2 hw_report_create

Create a report containing the test machines hw config as set in the hardware
db. Leave the sending to caller

@param int - testrun id

@return success - (0, hw_report)
@return error   - (1, error string)

=cut

sub hw_report_create
{
        my ($self, $testrun_id) = @_;
        my $testrun = model->resultset('Testrun')->find($testrun_id);
        my $host;
        eval {
                # parts of this chain may be undefined

                $host = $testrun->testrun_scheduling->host;
        };
        return (1, qq(testrun '$testrun_id' has no host associated)) unless $host;

        my $data = get_hardware_overview($host->id);
        my $yaml = Dump($data);
        $yaml   .= "...\n";
        $yaml =~ s/^(.*)$/  $1/mg;  # indent
        my $report = sprintf("
TAP Version 13
1..2
# Tapper-Reportgroup-Testrun: %s
# Tapper-Suite-Name: Hardwaredb Overview
# Tapper-Suite-Version: %s
# Tapper-Machine-Name: %s
ok 1 - Getting hardware information
%s
ok 2 - Sending
", $testrun_id, $Tapper::MCP::VERSION, $host->name, $yaml);

        return (0, $report);
}

1;