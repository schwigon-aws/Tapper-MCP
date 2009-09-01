use MooseX::Declare;

use 5.010;

class Artemis::MCP::Scheduler::MergedQueue
{
        use Artemis::Exception::Param;

        use Artemis::Model 'model';
        use aliased 'Artemis::MCP::Scheduler::TestRequest';
        use Data::Dumper;

        method _hostname($testrun) {
                return unless ($testrun and $testrun->hardwaredb_systems_id);
                return model('HardwareDB')->resultset('Systems')->find($testrun->hardwaredb_systems_id)->systemname;
        }

        method _max_seq {
                my $rs = model('TestrunDB')->resultset('TestrunScheduling')->search
                    (
                     { mergedqueue_seq => { '>', 0 } },
                     {
                      select => [ { max => 'mergedqueue_seq' } ],
                      as     => [ 'max_seq' ], }
                    )->first->get_column('max_seq');
        }

        method add(Testrun $tr)
        {
                my $max_seq = $self->_max_seq;
                $tr->mergedqueue_seq($max_seq + 1);
        }

        method get_testrequests
        {
                no strict 'refs';
                my $testrequests_rs = model('TestrunDB')->resultset('TestrunScheduling')->search
                    ({
                      mergedqueue_seq => { '>', 0 }
                     },
                     {
                      order_by => 'mergedqueue_seq'
                     }
                    );
                return $testrequests_rs;
        }
}

{
        # help the CPAN indexer
        package Artemis::MCP::Scheduler::Queue;
        our $VERSION = '0.01';
}

__END__

=head1 NAME

Artemis::MCP::Scheduler::Queue - Object for test queue abstraction

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 get_test_request

Get a testrequest for one of the free hosts provided as parameter.

@param array ref - list of hostnames

@return success               - Job
@return no fitting tr found   - 0

=head2 produce


Call the producer method associated with this object.

@param string - hostname

@return success - test run id
@return error   - exception



=head1 AUTHOR

Maik Hentsche, C<< <maik.hentsche at amd.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Maik Hentsche, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

# Idea: provide functions that map to feature has

1;
