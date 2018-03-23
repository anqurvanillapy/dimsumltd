unit module Monash;

my grammar Monash::Compiler {
    token TOP {
        | <.ws> <expr>
        | { self.panic($/, "Bad expr"); }
    }

    rule expr {
        | <term> + % <monad-op>
        | { self.panic($/, "Bad expr"); }
    }

    proto rule monad-op     {*}
    rule monad-op:sym<then> { '>>' }
    rule monad-op:sym<bind> { '>>=' }

    rule term {
        | <cmd-arg> + % <.ws>
        | <lambda>
        | { self.panic($/, "Bad cmds"); }
    }

    token cmd-arg {
        | '"' (<!before '"'> . )* '"'
        | \w+
    }

    rule lambda {
        | "\\" <lambda-arg-list> "->" <lambda-body>
        | { self.panic($/, "Bad lambda expr"); }
    }

    rule lambda-arg-list {
        | <lambda-arg> + % <.ws>
        | { self.panic($/, "Bad lambda args"); }
    }

    token lambda-arg { <:L> }

    rule lambda-body {
        |  <lambda-body-arg> + % <.ws>
        | { self.panic($/, "Bad lambda body"); }
    }

    token lambda-body-arg { ( <:L> | <arith-op> | \d ) }
    token arith-op { ( "+" | "-" | "*" | "/" ) }

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
        my @terms = $<term>>>.made;
        my @ops = $<monad-op>>>.made;
        @ops.push(";");
        make flat(@terms Z @ops).join(" ");
    }

    method monad-op:sym<then>($/) { make ";"; }
    method monad-op:sym<bind>($/) { make "|"; }

    method term($/) {
        make $<lambda> ?? $<lambda>.made !! $<cmd-arg>.join(" ");
    }

    method lambda($/) {
        my @argset = $<lambda-arg-list>.made>>.Str;
        my @body-args = $<lambda-body><lambda-body-arg>;

        my @has-bad-args = @body-args>>.Str.grep: /<:L>/ & none(@argset);
        if @has-bad-args {
            my $pos = $/.CURSOR.pos;
            die "(at $pos) Unbound variables found in lambda body";
        }

        given @body-args {
            my @sh-args = $_>>.Str>>.subst: /<:L>/, "\$" ~ *;
            my $body-ret = $_.grep({ .[0]<arith-op> })
                ?? "echo \$((" ~ @sh-args ~ "))"
                !! "echo " ~ @sh-args;
            make "(_()\{ read $<lambda-arg-list>; $body-ret;\};_)";
        }
    }

    method lambda-arg-list($/) {
        my @lambda-arg = $<lambda-arg>;
        my @argset = $<lambda-arg>.unique :as(*.Str);

        if @argset !eqv $<lambda-arg> {
            my $pos = $/.CURSOR.pos;
            die "(at $pos) Lambda args '$<lambda-arg>' should be unique";
        }

        make @argset;
    }
}
