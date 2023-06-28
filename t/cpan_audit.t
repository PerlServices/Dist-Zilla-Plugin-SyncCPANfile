#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestCPANfile;
use Clone qw(clone);

use Dist::Zilla::Plugin::SyncCPANfile;

my $log = '';

{
    no warnings 'redefine';

    sub Dist::Zilla::Plugin::SyncCPANfile::log {
        my ($self, $msg) = @_;

        $log .= $msg . "\n";
    }
}

sub test_cpanfile {
    my $desc    = shift;
    my $prereqs = shift;
    my $config  = shift;
    my $test    = build_dist( clone( $prereqs ), $config);

    my $content = $test->{cpanfile}->slurp_raw;
    ok check_cpanfile( $content, $prereqs ), $desc;

    like $content, qr/"ExtUtils::MakeMaker"\s+=>\s+"?(?!0)/;

    my ($version) =  $content =~ m/"ExtUtils::MakeMaker"\s+=>\s+"?[0-9]+/;
    cmp_ok $version, '>', 0;

    like $log, qr/Mojo::File 8 is vulnerable/;
}

test_cpanfile
  'change cpanfile name - simple prereq',
  [
      Prereqs => [
          'Mojo::File' => 8,
          'ExtUtils::MakeMaker' => 0,
      ]
  ],
  { cpan_audit => 1 }
;

done_testing;
