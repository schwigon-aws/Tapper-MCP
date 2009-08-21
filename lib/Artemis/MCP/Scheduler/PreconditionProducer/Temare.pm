use MooseX::Declare;

class Artemis::MCP::Scheduler::PreconditionProducer::Temare extends Artemis::MCP::Scheduler::PreconditionProducer {
        use YAML::Syck;

        use aliased 'Artemis::MCP::Scheduler::TestRequest';
        use aliased 'Artemis::MCP::Scheduler::Job';

        our $temarepath="/home/artemis/temare";

        $ENV{PYTHONPATH} .= ":$temarepath/src";
        our $artemispath="/home/artemis/perl510/";
        our $execpath="$artemispath/bin";
        our $grub_precondition=14;
        our $filename="/tmp/temare.yml";


        method produce(TestRequest $request)
        {
                # warn "FIXME XXX TODO";
                # return;

                my $host          =  $request->on_host->name;
                my $yaml   = qx($temarepath/temare subjectprep $host);
                return if $?;
                my $config = Load($yaml);
                my $precond_id;

                if ($config) {
                        open (FH,">",$filename) or die "Can't open $filename:$!";
                        print FH $yaml;
                        close FH or die "Can't write $filename:$!";
                        open(FH, "$execpath/artemis-testrun newprecondition --condition_file=$filename|") or die "Can't open pipe:$!";
                        $precond_id = <FH>;
                        chomp $precond_id;
                }

                if (not $precond_id) {
                        system("cp $filename $filename.backup");
                        return;
                }

                my $testrun;
                if ($config->{name} eq "automatically generated KVM test") {
                        $testrun    = qx($execpath/artemis-testrun new --topic=KVM --precondition=$precond_id --host=$host);
                        print "KVM on $host with precondition $precond_id: $testrun";
                } else {
                        $testrun    = qx($execpath/artemis-testrun new --topic=Xen --precondition=$grub_precondition --precondition=$precond_id --host=$host);
                        print "Xen on $host with preconditions $grub_precondition, $precond_id: $testrun";
                }
                my $job = Job->new(host => $request->on_host, testrunid => $testrun);
                return $job;
        }

}

{
        # help the CPAN indexer
        package Artemis::MCP::Scheduler::Producer::Temare;
        our $VERSION = '0.01';
}

1;

__END__


=head1 NAME

Artemis::MCP::Scheduler::PreconditionProducer::Temare - Wraps the existing temare producer

=head1 SYNOPSIS


=cut

=head2 features

=head1 AUTHOR

Maik Hentsche, C<< <maik.hentsche at amd.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Maik Hentsche, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
