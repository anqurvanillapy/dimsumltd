unit module Monash;

my grammar Monash::Compiler {
    token TOP {
        | <.ws> <expr>
        | { self.panic($/, "Bad expression") }
    }

    rule expr {
        | <term> + % <monad-op>
        | { self.panic($/, "Bad expression") }
    }

    rule term {
        | <arg> + % <.ws>
        | { self.panic($/, "Bad commands") }
    }

    proto rule monad-op     {*}
    rule monad-op:sym<then> { '>>' }
    rule monad-op:sym<bind> { '>>=' }

    token arg   { ('"' (<!before '"'> . )* '"' | \w+ ) }

    method panic($/, $err) {
        my $pos = $/.CURSOR.pos;
        die "(at $pos) $err";
    }
}

my class Monash::Actions {
    method TOP($/) {
        make $<expr>.made;
    }

    method expr($/) {
        my @terms = map *.made, $<term>;
        my @ops = map *.made, $<monad-op>;
        @ops.push(";");
        make flat(@terms Z @ops).join(" ");
    }

    method monad-op:sym<then>($/) { make ";"; }
    method monad-op:sym<bind>($/) { make "|"; }

    method term($/) {
        make $<arg>.join(" ");
    }
}
