package Tapper::MCP::Scheduler::Host;

use strict;
use warnings;

use Moose;
use Tapper::Model 'model';
use Tapper::MCP::Scheduler::ObjectBuilder;



has id         => (is => 'ro');
has name       => (is => 'ro');
has comment    => (is => 'ro');
has free       => (is => 'ro');
has active     => (is => 'ro');
has is_deleted => (is => 'ro');
has created_at => (is => 'ro');
has updated_at => (is => 'ro');

has queues => (is => 'ro',
               lazy => 1,
               default => sub {
                       my ($self) = shift;
                       my @return_queues;
                       my $queue_hosts = model('TestrunDB')->resultset('QueueHost')->search({host_id => $self->id});
                       my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;

                       while (my $this_queue = $queue_hosts->next) {
                               my $q = model->resultset('Queue')->search({id => $this_queue->queue->id},{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
                               push @return_queues, $obj_builder->new_queue(%{$q->search({}, {rows => 1})->first});
                       }
                       return \@return_queues;
               });
has features   => (is => 'ro',
                   lazy => 1,
                   default => sub {
                           my ($self) = shift;
                           my @return_feat;
                           my $feats = model('TestrunDB')->resultset('HostFeature')->search({host_id => $self->id});
                           $feats->result_class('DBIx::Class::ResultClass::HashRefInflator');
                           while (my $this_feat = $feats->next) {
                                   push @return_feat, $this_feat;
                           }
                           return \@return_feat;
                   });



1;

=head1 NAME

Tapper::MCP::Scheduler::Queue - Queue object for Tapper scheduler


=head1 SYNOPSIS

Abstraction for the database table.



=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>


=head1 BUGS

None.


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

