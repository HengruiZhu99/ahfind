#include "Piraha.hpp"

using namespace cctki_piraha;

smart_ptr<Grammar> AutoGrammar::reparserGenerator() {
    smart_ptr<Grammar> g = new Grammar();
    Grammar *gptr = g.ptr();
    g->patterns.put("named",new Seq(
                new Literal('{'),
                new Lookup("name",gptr),
                new Literal('}'),NULL));
    g->patterns.put("neg",new Literal('^'));
    g->patterns.put("backref",new Seq(
                new Literal('\\'),
                (new Bracket(false))
                ->addRange('1','9'),NULL));
    g->patterns.put("range",new Seq(
                new Lookup("cchar",gptr),
                new Literal('-'),
                new Lookup("cchar",gptr),NULL));
    g->patterns.put("pelem",new Or(
                new Seq(
                    new Or(
                        new Lookup("named",gptr),
                        new Lookup("dot",gptr),
                        new Lookup("backref",gptr),
                        new Lookup("literal",gptr),
                        new Lookup("charclass",gptr),
                        new Lookup("group",gptr),NULL),
                    new Or(
                        new Lookup("quant",gptr),
                        new Nothing(),NULL),NULL),
                new Or(
                    new Lookup("start",gptr),
                    new Lookup("end",gptr),
                    new Lookup("boundary",gptr),NULL),NULL));
    g->patterns.put("group_inside",new Seq(
                new Lookup("pelems",gptr),
                new Multi(new Seq(
                        new Literal('|'),
                        new Lookup("pelems",gptr),NULL),0,max_int),
                new Or(
                    new Seq(
                        new Lookup("nothing",gptr),
                        new Literal('|'),NULL),
                    new Nothing(),NULL),NULL));
    g->patterns.put("lookahead",new Seq(
                new Literal('?'),
                new Literal('='),NULL));
    g->patterns.put("boundary",new Seq(
                new Literal('\\'),
                new Literal('b'),NULL));
    g->patterns.put("dot",new Literal('.'));
    g->patterns.put("ign_on",new Seq(
                new Literal('?'),
                new Literal('i'),
                new Literal(':'),NULL));
    g->patterns.put("echar",new Literal('-'));
    g->patterns.put("hex",new Multi((new Bracket(false))
                ->addRange('0','9')
                ->addRange('A','F')
                ->addRange('a','f')
                ,4,4));
    g->patterns.put("name",new Seq(
                new Multi(new Literal('-'),0,1),
                (new Bracket(false))
                ->addRange(':',':')
                ->addRange('A','Z')
                ->addRange('_','_')
                ->addRange('a','z')
                ,
                new Multi((new Bracket(false))
                    ->addRange('0',':')
                    ->addRange('A','Z')
                    ->addRange('_','_')
                    ->addRange('a','z')
                    ,0,max_int),NULL));
    g->patterns.put("end",new Literal('$'));
    g->patterns.put("cchar",new Or(
                new Seq(
                    new Literal('\\'),
                    new Literal('u'),
                    new Lookup("hex",gptr),NULL),
                new Seq(
                    new Literal('\\'),
                    (new Bracket(true)),NULL),
                (new Bracket(true))
                ->addRange('-','-')
                ->addRange('\\',']')
                ,NULL));
    g->patterns.put("neglookahead",new Seq(
                new Literal('?'),
                new Literal('!'),NULL));
    g->patterns.put("charclass",new Seq(
                new Literal('['),
                new Multi(new Lookup("neg",gptr),0,1),
                new Multi(new Or(
                        new Lookup("range",gptr),
                        new Lookup("echar",gptr),NULL),0,1),
                new Multi(new Or(
                        new Lookup("range",gptr),
                        new Lookup("cchar",gptr),NULL),0,max_int),
                new Multi(new Lookup("echar",gptr),0,1),
                new Literal(']'),NULL));
    g->patterns.put("quantmax",new Seq(
                new Literal(','),
                new Multi(new Lookup("num",gptr),0,1),NULL));
    g->patterns.put("pelems",new Seq(
                new Lookup("pelem",gptr),
                new Multi(new Lookup("pelem",gptr),0,max_int),NULL));
    g->patterns.put("ign_off",new Seq(
                new Literal('?'),
                new Literal('-'),
                new Literal('i'),
                new Literal(':'),NULL));
    g->patterns.put("num",new Multi((new Bracket(false))
                ->addRange('0','9')
                ,1,max_int));
    g->patterns.put("pattern",new Seq(
                new Start(),
                new Or(
                    new Lookup("group_inside",gptr),
                    new Nothing(),NULL),
                new End(),NULL));
    g->patterns.put("start",new Literal('^'));
    g->patterns.put("quant",new Or(
                new Literal('+'),
                new Literal('*'),
                new Literal('?'),
                new Seq(
                    new Literal('{'),
                    new Lookup("num",gptr),
                    new Multi(new Lookup("quantmax",gptr),0,1),
                    new Literal('}'),NULL),NULL));
    g->patterns.put("nothing",new Nothing());
    g->patterns.put("group",new Seq(
                new Literal('('),
                new Or(
                    new Lookup("ign_on",gptr),
                    new Lookup("ign_off",gptr),
                    new Lookup("lookahead",gptr),
                    new Lookup("neglookahead",gptr),
                    new Nothing(),NULL),
                new Or(
                    new Lookup("group_inside",gptr),
                    new Nothing(),NULL),
                new Literal(')'),NULL));
    g->patterns.put("literal",new Or(
                new Seq(
                    new Literal('\\'),
                    new Literal('u'),
                    new Lookup("hex",gptr),NULL),
                new Seq(
                    new Literal('\\'),
                    (new Bracket(true))
                    ->addRange('b','b'),
                    NULL
                    ),
                (new Bracket(true))
                ->addRange('$','$')
                ->addRange('(','+')
                ->addRange('.','.')
                ->addRange('?','?')
                ->addRange('[','^')
                ->addRange('{','}')
                ,NULL));
    return g;
}
  
smart_ptr<Grammar> AutoGrammar::fileParserGenerator() {
    smart_ptr<Grammar> g = new Grammar();
    Grammar *gptr = g.ptr();
    g->patterns.put("named",new Seq(
                new Literal('{'),
                new Lookup("name",gptr),
                new Literal('}'),NULL));
    g->patterns.put("neg",new Literal('^'));
    g->patterns.put("backref",new Seq(
                new Literal('\\'),
                (new Bracket(false))
                ->addRange('1','9'),NULL
                ));
    g->patterns.put("range",new Seq(
                new Lookup("cchar",gptr),
                new Literal('-'),
                new Lookup("cchar",gptr),NULL));
    g->patterns.put("pelem",new Or(
                new Seq(
                    new Or(
                        new Lookup("named",gptr),
                        new Lookup("dot",gptr),
                        new Lookup("backref",gptr),
                        new Lookup("literal",gptr),
                        new Lookup("charclass",gptr),
                        new Lookup("group",gptr),NULL),
                    new Or(
                        new Lookup("quant",gptr),
                        new Nothing(),NULL),NULL),
                new Or(
                    new Lookup("start",gptr),
                    new Lookup("end",gptr),
                    new Lookup("boundary",gptr),NULL),NULL));
    g->patterns.put("pelems_next",new Seq(
                new Multi(new Lookup("s",gptr),0,1),
                new Literal('|'),
                new Multi(new Lookup("s",gptr),0,1),
                new Lookup("pelem",gptr),
                new Multi(new Seq(
                        new Multi(new Lookup("s0",gptr),0,1),
                        new Lookup("pelem",gptr),NULL),0,max_int),NULL));
    g->patterns.put("group_inside",new Seq(
                new Lookup("pelems",gptr),
                new Multi(new Seq(
                        new Literal('|'),
                        new Lookup("pelems",gptr),NULL),0,max_int),
                new Or(
                    new Seq(
                        new Multi(new Lookup("s0",gptr),0,1),
                        new Lookup("nothing",gptr),
                        new Literal('|'),NULL),
                    new Nothing(),NULL),
                new Multi(new Lookup("s",gptr),0,1),NULL));
    g->patterns.put("lookahead",new Seq(
                new Literal('?'),
                new Literal('='),NULL));
    g->patterns.put("boundary",new Seq(
                new Literal('\\'),
                new Literal('b'),NULL));
    g->patterns.put("dot",new Literal('.'));
    g->patterns.put("pelems_top",new Seq(
                new Lookup("pelem",gptr),
                new Multi(new Seq(
                        new Multi(new Lookup("s0",gptr),0,1),
                        new Lookup("pelem",gptr),NULL),0,max_int),NULL));
    g->patterns.put("ign_on",new Seq(
                new Literal('?'),
                new Literal('i'),
                new Literal(':'),NULL));
    g->patterns.put("echar",new Literal('-'));
    g->patterns.put("hex",new Multi((new Bracket(false))
                ->addRange('0','9')
                ->addRange('A','F')
                ->addRange('a','f')
                ,4,4));
    g->patterns.put("file",new Seq(
                new Start(),
                new Multi(new Lookup("-s",gptr),0,1),
                new Lookup("rule",gptr),
                new Multi(new Seq(
                        new Multi(new Lookup("-s",gptr),0,1),
                        new Lookup("rule",gptr),NULL),0,max_int),
                new Multi(new Lookup("-s",gptr),0,1),
                new End(),NULL));
    g->patterns.put("name",new Seq(
                new Multi(new Literal('-'),0,1),
                (new Bracket(false))
                ->addRange(':',':')
                ->addRange('A','Z')
                ->addRange('_','_')
                ->addRange('a','z')
                ,
                new Multi((new Bracket(false))
                    ->addRange('0',':')
                    ->addRange('A','Z')
                    ->addRange('_','_')
                    ->addRange('a','z')
                    ,0,max_int),NULL));
    g->patterns.put("rule",new Seq(
                new Lookup("name",gptr),
                new Lookup("-w",gptr),
                new Literal('='),
                new Lookup("-w",gptr),
                new Lookup("pattern",gptr),NULL));
    g->patterns.put("end",new Literal('$'));
    g->patterns.put("cchar",new Or(
                new Seq(
                    new Literal('\\'),
                    new Literal('u'),
                    new Lookup("hex",gptr),NULL),
                new Seq(
                    new Literal('\\'),
                    (new Bracket(true))
                    ,NULL),
                (new Bracket(true))
                ->addRange('-','-')
                ->addRange('\\',']')
                ,NULL));
    g->patterns.put("s0",new Multi((new Bracket(false))
                ->addRange('\t','\t')
                ->addRange(' ',' ')
                ,1,max_int));
    g->patterns.put("neglookahead",new Seq(
                new Literal('?'),
                new Literal('!'),NULL));
    g->patterns.put("charclass",new Seq(
                new Literal('['),
                new Multi(new Lookup("neg",gptr),0,1),
                new Multi(new Or(
                        new Lookup("range",gptr),
                        new Lookup("echar",gptr),NULL),0,1),
                new Multi(new Or(
                        new Lookup("range",gptr),
                        new Lookup("cchar",gptr),NULL),0,max_int),
                new Multi(new Lookup("echar",gptr),0,1),
                new Literal(']'),NULL));
    g->patterns.put("quantmax",new Seq(
                new Literal(','),
                new Multi(new Lookup("num",gptr),0,1),NULL));
    g->patterns.put("group_top",new Seq(
                new Lookup("pelems_top",gptr),
                new Multi(new Lookup("pelems_next",gptr),0,max_int),
                new Or(
                    new Seq(
                        new Multi(new Lookup("s",gptr),0,1),
                        new Lookup("nothing",gptr),
                        new Literal('|'),NULL),
                    new Nothing(),NULL),NULL));
    g->patterns.put("pelems",new Seq(
                new Multi(new Seq(
                        new Multi(new Lookup("s",gptr),0,1),
                        new Lookup("pelem",gptr),NULL),1,max_int),
                new Multi(new Lookup("s",gptr),0,1),NULL));
    g->patterns.put("ign_off",new Seq(
                new Literal('?'),
                new Literal('-'),
                new Literal('i'),
                new Literal(':'),NULL));
    g->patterns.put("w",new Multi((new Bracket(false))
                ->addRange('\t','\t')
                ->addRange(' ',' ')
                ,0,max_int));
    g->patterns.put("num",new Multi((new Bracket(false))
                ->addRange('0','9')
                ,1,max_int));
    g->patterns.put("s",new Multi(new Or(
                    (new Bracket(false))
                    ->addRange('\t','\n')
                    ->addRange('\r','\r')
                    ->addRange(' ',' ')
                    ,
                    new Seq(
                        new Literal('#'),
                        new Multi(new Dot(),0,max_int),NULL),NULL),1,max_int));
    g->patterns.put("pattern",new Or(
                new Lookup("group_top",gptr),
                new Nothing(),NULL));
    g->patterns.put("start",new Literal('^'));
    g->patterns.put("quant",new Or(
                new Literal('+'),
                new Literal('*'),
                new Literal('?'),
                new Seq(
                    new Literal('{'),
                    new Lookup("num",gptr),
                    new Multi(new Lookup("quantmax",gptr),0,1),
                    new Literal('}'),NULL),NULL));
    g->patterns.put("nothing",new Nothing());
    g->patterns.put("group",new Seq(
                new Literal('('),
                new Or(
                    new Lookup("ign_on",gptr),
                    new Lookup("ign_off",gptr),
                    new Lookup("lookahead",gptr),
                    new Lookup("neglookahead",gptr),
                    new Nothing(),NULL),
                new Or(
                    new Lookup("group_inside",gptr),
                    new Nothing(),NULL),
                new Literal(')'),NULL));
    g->patterns.put("literal",new Or(
                new Seq(
                    new Literal('\\'),
                    new Literal('u'),
                    new Lookup("hex",gptr),NULL),
                new Seq(
                    new Literal('\\'),
                    (new Bracket(true))
                    ->addRange('1','9')
                    ->addRange('b','b')
                    ,NULL),
                (new Bracket(true))
                ->addRange('\n','\n')
                ->addRange('\r','\r')
                ->addRange('$','$')
                ->addRange('(','+')
                ->addRange('.','.')
                ->addRange('?','?')
                ->addRange('[','^')
                ->addRange('{','}')
                ,NULL));
    return g;
}
