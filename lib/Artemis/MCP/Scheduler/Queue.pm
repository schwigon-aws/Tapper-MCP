use MooseX::Declare;

class Artemis::MCP::Scheduler::Queue {
        use Artemis::Exception::Param;
        use Artemis::MCP::Scheduler::Host;
        use Artemis::MCP::Scheduler::TestRequest;

=head1 NAME
        
   Artemis::MCP::Scheduler::Queue - Object for test queue abstraction

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

=cut
        

        has name         => (is => 'rw', default => '');
        has producer     => (is => 'rw');
        has share        => (is => 'rw', isa => 'Num');
        has testrequests => (is => 'rw', isa => 'ArrayRef');
        has runcount     => (is => 'rw', default => 0); # WFQ specific

=head1 FUNCTIONS

=cut


=head2 get_test_request

Get a testrequest for one of the free hosts provided as parameter.

@param array ref - list of hostnames

@return success               - TestRequest
@return no fitting tr found   - 0

=cut

        method get_test_request(ArrayRef $free_hosts) {
                return 0 if not $self->testrequests and ref $self->testrequests eq 'ARRAY';
                foreach my $testrequest(@{$self->testrequests}) {
                        return $testrequest if $testrequest->fits($free_hosts);
                }
                return 0;
        }

=head2 produce


Call the producer method associated with this object.

@param string - hostname

@return success - test run id
@return error   - exception

=cut

        method produce(Artemis::MCP::Scheduler::TestRequest $request) {
                die Artemis::Exception::Param->new("Client ".$self->name."does not have an associated producer")
                    if not $self->producer ;
                return $self->producer->produce($request);
        }



}

{
        # just for CPAN
        package Artemis::MCP::Scheduler::Queue;
        our $VERSION = '0.01';
}


=head1 AUTHOR

Maik Hentsche, C<< <maik.hentsche at amd.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Maik Hentsche, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

# Idea: provide functions that map to feature has

1;

