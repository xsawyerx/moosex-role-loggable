#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

{
    package Foo;
    use Moo;
    with 'MooseX::Role::Loggable';
}

my $foo = Foo->new;

ok(
    can_ok( $foo, 'logger' ),
    'Logger object',
);

isa_ok( $foo->logger, 'Log::Dispatchouli' );
is( $foo->logger_ident, 'MooseX::Role::Loggable', 'Correct ident' );

