#! /usr/bin/env perl

use strict;
use warnings;

use Test::Fixture::DBIC::Schema;
use YAML;

use Artemis::Schema::TestTools;

use Test::More;
use Test::Deep;

BEGIN { use_ok('Artemis::MCP::Config'); }


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_xenpreconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $producer = Artemis::MCP::Config->new(2);
isa_ok($producer, "Artemis::MCP::Config", 'Producer object created');

my $config = $producer->create_config(1235);     # expects a port number
is(ref($config),'HASH', 'Config created');

is($config->{preconditions}->[0]->{image}, "suse/suse_sles10_64b_smp_raw.tar.gz", 'first precondition is root image');

cmp_deeply($config->{preconditions},
           supersetof({
                       precondition_type => 'package',
                       filename => "artemisutils/opt-artemis64.tar.gz",
                      },
                      {
                       precondition_type => 'package',
                       filename => 'artemisutils/opt-artemis64.tar.gz',
                       mountpartition => undef,
                       mountfile => '/kvm/images/raw.img'
                      },
                      {
                       'config' => {
                                    'guests' => [
                                                 {
                                                  'exec' => '/usr/share/artemis/packages/mhentsc3/startkvm.pl'
                                                 }
                                                ],
                                    'guest_count' => 1
                                   },
                       'precondition_type' => 'prc'
                      },
                      {
                       'config' => {
                                    testprogram_list => [
                                                         {
                                                         'runtime' => '5',
                                                         'program' => '/home/artemis/x86_64/bin/artemis_testsuite_kernbench.sh',
                                                         'timeout' => 36000,
                                                         },
                                                        ],
                                    'guest_number' => 1,
                                   },
                       'mountpartition' => undef,
                       'precondition_type' => 'prc',
                       'mountfile' => '/kvm/images/raw.img'
                      },),
           'Choosen subset of the expected preconditions');

is($config->{installer_stop}, 1, 'installer_stop');


my $info = $producer->get_mcp_info();
isa_ok($info, 'Artemis::MCP::Info', 'mcp_info');
my @timeout = $info->get_testprogram_timeouts(1);
is_deeply(\@timeout,[36000],'Timeout for testprogram in PRC 1');

$producer = Artemis::MCP::Config->new(3);
$config = $producer->create_config();
is(ref($config),'HASH', 'Config created');
is($config->{preconditions}->[3]->{config}->{max_reboot}, 2, 'Reboot test');

$info = $producer->get_mcp_info();
isa_ok($info, 'Artemis::MCP::Info', 'mcp_info');
my $timeout = $info->get_boot_timeout(0);
is($timeout, 5, 'Timeout booting PRC 0');


#---------------------------------------------------

$producer = Artemis::MCP::Config->new(4);

$config = $producer->create_config(1337);   # expects a port number
is(ref($config),'HASH', 'Config created');

my $expected_grub = qr(timeout 2

title RHEL 5
kernel /tftpboot/stable/rhel/5/x86_64/vmlinuz  console=ttyS0,115200 ks=http://bancroft/autoinstall/stable/rhel/5/x86_64/artemis-ai.ks ksdevice=eth0 noapic artemis_ip=\d{1,3}\.\d{1,3}.\d{1,3}.\d{1,3} artemis_host=$config->{mcp_host} artemis_port=1337 artemis_environment=test
initrd /tftpboot/stable/rhel/5/x86_64/initrd.img
);

like($config->{installer_grub}, $expected_grub, 'Installer grub set by autoinstall precondition');

cmp_deeply($config->{preconditions},
           supersetof(
                      {
                       precondition_type => 'package',
                       filename => "artemisutils/opt-artemis64.tar.gz",
                       'mountpartition' => undef,
                       'mountfile' => '/kvm/images/raw.img'
                     },
                      {
                       'config' => {
                                    testprogram_list => [
                                                         {
                                                          runtime => '5',
                                                          program => '/home/artemis/x86_64/bin/artemis_testsuite_kernbench.sh',
                                                          timeout => 36000,
                                                         },
                                                        ],
                                    'guest_number' => 1,
                                   },
                       'mountpartition' => undef,
                       'precondition_type' => 'prc',
                       'mountfile' => '/kvm/images/raw.img'
                      },
                      {
                       'config' => {
                                    'guests' => [
                                                 {
                                                  'exec' => '/usr/share/artemis/packages/mhentsc3/startkvm.pl'
                                                 }
                                                ],
                                    'guest_count' => 1
                                   },
                       'precondition_type' => 'prc'
                      }),
           'Choosen subset of the expected preconditions');

$producer = Artemis::MCP::Config->new(5);

$config = $producer->create_config(1337);   # expects a port number
is(ref($config),'HASH', 'Config created');

is_deeply($config->{preconditions}->[0],
          {
           'mount' => '/',
           'precondition_type' => 'image',
           'partition' => [
                           'testing',
                           '/dev/sda2',
                           '/dev/hda2'
                          ],
           'image' => 'suse/suse_sles10_64b_smp_raw.tar.gz'
          },
          'Partition alternatives');

$producer = Artemis::MCP::Config->new(6);

$config = $producer->create_config(1337);   # expects a port number
is(ref($config),'HASH', 'Config created');

cmp_deeply($config->{preconditions},
           supersetof({'dest'              => '/xen/images/002-uruk-1268101895.img',
                       'name'              => 'osko:/export/image_files/official_testing/windows_test.img',
                       'protocol'          => 'nfs',
                       'precondition_type' => 'copyfile'
                      },
                      {
                       precondition_type => 'package',
                       filename => 'artemisutils/opt-artemis32.tar.gz',
                       mountpartition => undef,
                       'mountfile' => '/xen/images/002-uruk-1268101895.img'
                      },
                      {
                       'config' => {
                                    testprogram_list => [
                                                         {
                                                          'runtime'  => '50',
                                                          'program' => '/opt/artemis/bin/metainfo',
                                                          'timeout'  => '300',
                                                          'parameters' => [
                                                                           '--foo=some bar'
                                                                          ],
                                                         },
                                                         {
                                                          'runtime' => '1200',
                                                          'timeout' => '1800',
                                                          'program' => '/opt/artemis/bin/py_kvm_unit'
                                                         }
                                                        ],
                                    'guests'         => [
                                                         {
                                                          'svm'      => '/xen/images//002-uruk-1268101895.svm'
                                                         }
                                                        ],
                                    'guest_count'    => 1
                                   },
                       'precondition_type' => 'prc'
                      },
                      {
                       'config' => {
                                    testprogram_list => [
                                                         {
                                                          'runtime' => '28800',
                                                          'program' => '/opt/artemis/bin/py_reaim',
                                                          'timeout' => '36000',
                                                          }
                                                        ],
                                    'guest_number' => 1
                                   },
                       'mountpartition' => undef,
                       'precondition_type' => 'prc',
                       'mountfile' => '/xen/images/002-uruk-1268101895.img'
                      },

                     ),
           'Choosen subset of the expected preconditions');

done_testing();
