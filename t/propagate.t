#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;

{
    package Foo;
    use Moo;
    with 'MooseX::Role::Loggable';

    sub bar { Bar->new( logger => shift->logger ) }
}

{
    package Bar;
    use Moo;
    with 'MooseX::Role::Loggable';
}

my $foo = Foo->new;
isa_ok( $foo, 'Foo' );
cmp_ok( $foo->debug, '==', 0, 'debug is off in Foo' );

my $bar = $foo->bar;
isa_ok( $bar, 'Bar' );
cmp_ok( $bar->debug, '==', 0, 'debug is off in Bar' );
    
$foo = Foo->new( debug => 1 );
isa_ok( $foo, 'Foo' );
cmp_ok( $foo->debug, '==', 1, 'debug is now on in Foo' );

$bar = $foo->bar;
isa_ok( $bar, 'Bar' );
cmp_ok( $bar->debug, '==', 1, 'debug is now on in Bar too' );
cmp_ok( $bar->logger->debug, '==', 1, 'debug is now on in Bar too' );

