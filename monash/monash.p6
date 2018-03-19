#!/usr/bin/env perl6

my grammar Monash {
    token TOP {
        | <.ws> <expr>
        | { self.panic($/, "Bad expression") }
    }

    rule expr {
        | <term> + % <bind-op>
        | { self.panic($/, "Bad expression") }
    }

    rule term {
        | <arg> + % <.ws>
        | { self.panic($/, "Bad commands") }
    }

    token bind-op   { '>>=' }
    token arg       { \w+ }

    method panic($/, $err) {
        my $pos = $/.CURSOR.pos;
        die "at $pos\: $err";
    }
}

my class MonashActions {
    method TOP($/) {
        make $<expr>.made;
    }

    method expr($/) {
        make join(' | ', map *.made, $<term>);
    }

    method term($/) {
        make $<arg>.join(' ');
    }
}

sub MAIN($src = (@*ARGS[0] // slurp)) {
    try Monash.parse($src, actions => MonashActions);
    if $! {
        say "Monash failed ", $!.message;
    } elsif $/ {
        shell $/.made;
    } else {
        die "Monash parsing failed."
    }
}
