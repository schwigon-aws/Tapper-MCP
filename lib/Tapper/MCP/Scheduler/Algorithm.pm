## no critic (RequireUseStrict)
package Tapper::MCP::Scheduler::Algorithm;
# ABSTRACT: name of the queue has to be unique

        use 5.010;
        use Moose;
        use Tapper::Model 'model';

        has queues => (
                       is         => 'rw',
                       isa        => 'HashRef',
                       default    => sub { model('TestrunDB')->resultset('Queue')->official_queuelist },
                      );

        sub queue_count {
                my ($self) = @_;

                scalar keys %{$self->queues}
        }

        sub add_queue {
                my ($self,  $q) = @_;

                my $qname = $q->name;
                if ($self->queues->{$qname}) {
                        warn "Queue with name '$qname' already exists";
                        return;
                }

                foreach (keys %{$self->queues})
                {
                        $self->queues->{$_}->runcount( 0 );
                }

                $self->queues->{$qname} = $q;
        }

        sub remove_queue {
                my ($self,  $q) = @_;
                delete $self->queues->{$q->name};
        }

        sub update_queue {
                my ($self,  $q) = @_;
                # interface
                die "Interface update_queue not implemented";
        }

        sub lookup_next_queue {
                my ($self) = @_;
                # interface
                die "Interface lookup_next_queue not implemented";
        }

        sub get_next_queue {
                my ($self) = @_;
                # interface
                die "Interface get_next_queue not implemented";
        }

        with 'MooseX::Traits';
1;

__END__

=head2 add_queue

Add a new queue to the scheduler.

@param Scheduler::Queue - 

@return success - 0
@return error   - error string


=head2 remove_queue

Remove a queue from scheduling

@param string - name of the queue to be removed

@return success - 0
@return error   - error string


=head2 update_queue

Update the time entry of the given queue

@param string - name of the queue

@return success - 0

=cut
