#!/usr/bin/env perl

use 5.044;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Util;

my @files = dir(regex => '\.pl$');
p @files;
