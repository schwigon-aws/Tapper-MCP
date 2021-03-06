#! /usr/bin/env perl

use strict;
use warnings;
use 5.010;

# get rid of warnings
use Class::C3;
use MRO::Compat;


use Tapper::Model 'model';

use Data::Dumper;
use Test::Fixture::DBIC::Schema;
use Tapper::Producer::Temare;

use Test::MemoryGrowth;
use Test::More 0.88;
use Test::MockModule;

# use Tapper::Schema::TestTools;
# # BEGIN{
# #         # --------------------------------------------------------------------------------
# #         construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_circle.yml' );
# # }
use aliased 'Tapper::MCP::Scheduler::Controller';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::WFQ';


my $algorithm = Algorithm->new_with_traits ( traits => [WFQ] );
my $scheduler = Controller->new (algorithm => $algorithm);

sub schedule_with_fork
{
        my $pid = open(my $fh, "-|");
        if ($pid == 0) {
                my $next_job = $scheduler->get_next_job;
                print $next_job->id;
                exit;
        } else {
                my $id = <$fh>;
                my $next_job = model('TestrunDB')->resultset('TestrunScheduling')->find($id);
                $scheduler->mark_job_as_finished($next_job);
        }

}

sub schedule_no_fork
{
        my $next_job = $scheduler->get_next_job;
        $scheduler->mark_job_as_finished($next_job);
}


# --------------------------------------------------

my $mock = new Test::MockModule('Tapper::Schema::TestrunDB::Result::TestrunScheduling');
$mock->mock('produce_preconditions',sub{return 0;});

my $next_job;

# This takes extremly long indeed. Yet you can not reduce the number of call significantly otherwise the memory leak wont be detected.
no_growth  { schedule_no_fork } calls => 10, 'get_next_job does not grow memory';
ok(1, 'Dummy');

done_testing();
