#! /usr/bin/env perl

use strict;
use warnings;


# get rid of warnings
use Class::C3;
use MRO::Compat;


use Artemis::Model 'model';

use Test::Fixture::DBIC::Schema;
use Artemis::Schema::TestTools;
use Artemis::MCP::Scheduler::PreconditionProducer::NewestPackage;
use Artemis::Config;
use File::Spec::Functions;

use Test::More;
use YAML;

# --------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_run2.yml' );
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# --------------------------------------------------------------------------------

qx(touch t/misc_files/kernel_producer/kernel/x86_64/kernel_file3.tar.gz);  # make sure file3 is the newest

my $host = bless{name => 'bullock'};
my $job  = bless{host => $host};

Artemis::Config->subconfig->{paths}{prc_nfs_mountdir} = 't/misc_files/';
my $producer     = Artemis::MCP::Scheduler::PreconditionProducer::NewestPackage->new();
my $precondition = $producer->produce($job, {source_dir => 't/misc_files/kernel_producer//kernel/x86_64'});

is(ref $precondition, 'HASH', 'Producer / returned hash');


my @yaml = Load($precondition->{precondition_yaml});
is( $yaml[0]->{precondition_type}, 'package', ' Precondition type');
is( canonpath($yaml[0]->{filename}), canonpath('t/misc_files/kernel_producer/kernel/x86_64/kernel_file3.tar.gz'), 'Precondition file name');


done_testing();