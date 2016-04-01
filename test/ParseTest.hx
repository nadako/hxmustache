import utest.Assert;
import mustache.Context;
import mustache.Token;

class ParseTest extends buddy.BuddySuite {

    static function throws(fn:Void->Void, re:EReg) {
        try fn() catch(e:String) {
            utest.Assert.match(re, e);
            return;
        } catch (e:Dynamic) {
            throw "not string thrown";
        }
        throw "no error thrown";
    }

    public function new() {
        super();
        var expectations = [
            ''                                        => [],
            '{{hi}}'                                  => [ new Token( Value(true), 'hi', 0, 6 ) ],
            '{{hi.world}}'                            => [ new Token( Value(true), 'hi.world', 0, 12 ) ],
            '{{hi . world}}'                          => [ new Token( Value(true), 'hi . world', 0, 14 ) ],
            '{{ hi}}'                                 => [ new Token( Value(true), 'hi', 0, 7 ) ],
            '{{hi }}'                                 => [ new Token( Value(true), 'hi', 0, 7 ) ],
            '{{ hi }}'                                => [ new Token( Value(true), 'hi', 0, 8 ) ],
            '{{{hi}}}'                                => [ new Token( Value(false), 'hi', 0, 8 ) ],
            '{{!hi}}'                                 => [ new Token( Comment, 'hi', 0, 7 ) ],
            '{{! hi}}'                                => [ new Token( Comment, 'hi', 0, 8 ) ],
            '{{! hi }}'                               => [ new Token( Comment, 'hi', 0, 9 ) ],
            '{{ !hi}}'                                => [ new Token( Comment, 'hi', 0, 8 ) ],
            '{{ ! hi}}'                               => [ new Token( Comment, 'hi', 0, 9 ) ],
            '{{ ! hi }}'                              => [ new Token( Comment, 'hi', 0, 10 ) ],
            'a\n b'                                   => [ new Token( Text, 'a\n b', 0, 4 ) ],
            'a{{hi}}'                                 => [ new Token( Text, 'a', 0, 1 ), new Token( Value(true), 'hi', 1, 7 ) ],
            'a {{hi}}'                                => [ new Token( Text, 'a ', 0, 2 ), new Token( Value(true), 'hi', 2, 8 ) ],
            ' a{{hi}}'                                => [ new Token( Text, ' a', 0, 2 ), new Token( Value(true), 'hi', 2, 8 ) ],
            ' a {{hi}}'                               => [ new Token( Text, ' a ', 0, 3 ), new Token( Value(true), 'hi', 3, 9 ) ],
            'a{{hi}}b'                                => [ new Token( Text, 'a', 0, 1 ), new Token( Value(true), 'hi', 1, 7 ), new Token( Text, 'b', 7, 8 ) ],
            'a{{hi}} b'                               => [ new Token( Text, 'a', 0, 1 ), new Token( Value(true), 'hi', 1, 7 ), new Token( Text, ' b', 7, 9 ) ],
            'a{{hi}}b '                               => [ new Token( Text, 'a', 0, 1 ), new Token( Value(true), 'hi', 1, 7 ), new Token( Text, 'b ', 7, 9 ) ],
            'a\n{{hi}} b \n'                          => [ new Token( Text, 'a\n', 0, 2 ), new Token( Value(true), 'hi', 2, 8 ), new Token( Text, ' b \n', 8, 12 ) ],
            'a\n {{hi}} \nb'                          => [ new Token( Text, 'a\n ', 0, 3 ), new Token( Value(true), 'hi', 3, 9 ), new Token( Text, ' \nb', 9, 12 ) ],
            'a\n {{!hi}} \nb'                         => [ new Token( Text, 'a\n', 0, 2 ), new Token( Comment, 'hi', 3, 10 ), new Token( Text, 'b', 12, 13 ) ],
            'a\n{{#a}}{{/a}}\nb'                      => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 2, 8, [], 8 ), new Token( Text, 'b', 15, 16 ) ],
            'a\n {{#a}}{{/a}}\nb'                     => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 3, 9, [], 9 ), new Token( Text, 'b', 16, 17 ) ],
            'a\n {{#a}}{{/a}} \nb'                    => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 3, 9, [], 9 ), new Token( Text, 'b', 17, 18 ) ],
            'a\n{{#a}}\n{{/a}}\nb'                    => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 2, 8, [], 9 ), new Token( Text, 'b', 16, 17 ) ],
            'a\n {{#a}}\n{{/a}}\nb'                   => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 3, 9, [], 10 ), new Token( Text, 'b', 17, 18 ) ],
            'a\n {{#a}}\n{{/a}} \nb'                  => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 3, 9, [], 10 ), new Token( Text, 'b', 18, 19 ) ],
            'a\n{{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb'    => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 2, 8, [], 9 ), new Token( Section(false), 'b', 16, 22, [], 23 ),  new Token( Text, 'b', 30, 31 ) ],
            'a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb'   => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 3, 9, [], 10 ), new Token( Section(false), 'b', 17, 23, [], 24 ), new Token( Text, 'b', 31, 32 ) ],
            'a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}} \nb'  => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 3, 9, [], 10 ), new Token( Section(false), 'b', 17, 23, [], 24 ), new Token( Text, 'b', 32, 33 ) ],
            'a\n{{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb'    => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 2, 8, [ new Token( Section(false), 'b', 9, 15, [], 16 ) ], 23 ),  new Token( Text, 'b', 30, 31 ) ],
            'a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb'   => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 3, 9, [ new Token( Section(false), 'b', 10, 16, [], 17 ) ], 24 ), new Token( Text, 'b', 31, 32 ) ],
            'a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}} \nb'  => [ new Token( Text, 'a\n', 0, 2 ), new Token( Section(false), 'a', 3, 9, [ new Token( Section(false), 'b', 10, 16, [], 17 ) ], 24 ), new Token( Text, 'b', 32, 33 ) ],
            '{{>abc}}'                                => [ new Token( Partial, 'abc', 0, 8 ) ],
            '{{> abc }}'                              => [ new Token( Partial, 'abc', 0, 10 ) ],
            '{{ > abc }}'                             => [ new Token( Partial, 'abc', 0, 11 ) ],
            '{{=<% %>=}}'                             => [ new Token( SetDelimiters, '<% %>', 0, 11 ) ],
            '{{= <% %> =}}'                           => [ new Token( SetDelimiters, '<% %>', 0, 13 ) ],
            '{{=<% %>=}}<%={{ }}=%>'                  => [ new Token( SetDelimiters, '<% %>', 0, 11 ), new Token( SetDelimiters, '{{ }}', 11, 22 ) ],
            '{{=<% %>=}}<%hi%>'                       => [ new Token( SetDelimiters, '<% %>', 0, 11 ), new Token( Value(true), 'hi', 11, 17 ) ],
            '{{#a}}{{/a}}hi{{#b}}{{/b}}\n'            => [ new Token( Section(false), 'a', 0, 6, [], 6 ), new Token( Text, 'hi', 12, 14 ), new Token( Section(false), 'b', 14, 20, [], 20 ), new Token( Text, '\n', 26, 27 ) ],
            '{{a}}\n{{b}}\n\n{{#c}}\n{{/c}}\n'        => [ new Token( Value(true), 'a', 0, 5 ), new Token( Text, '\n', 5, 6 ), new Token( Value(true), 'b', 6, 11 ), new Token( Text, '\n\n', 11, 13 ), new Token( Section(false), 'c', 13, 19, [], 20 ) ],
            '{{#foo}}\n  {{#a}}\n    {{b}}\n  {{/a}}\n{{/foo}}\n' => [
                new Token( Section(false), 'foo', 0, 8, [ new Token( Section(false), 'a', 11, 17, [ new Token( Text, '    ', 18, 22 ), new Token( Value(true), 'b', 22, 27 ), new Token( Text, '\n', 27, 28 ) ], 30 ) ], 37 )
            ]
        ];

        describe('Mustache.parse', function () {

            for (template in expectations.keys()) {
                it('knows how to parse ' + haxe.Json.stringify(template), function () {
                    Assert.same(expectations[template], Mustache.parse(template));
                });
            }

            describe('when there is an unclosed tag', function () {
                it('throws an error', function () {
                    throws(function () {
                        Mustache.parse('My name is {{name');
                    }, ~/unclosed tag at 17/i);
                });
            });

            describe('when there is an unclosed section', function () {
                it('throws an error', function () {
                    throws(function () {
                        Mustache.parse('A list: {{#people}}{{name}}');
                    }, ~/unclosed section "people" at 27/i);
                });
            });

            describe('when there is an unopened section', function () {
                it('throws an error', function () {
                    throws(function () {
                        Mustache.parse('The end of the list! {{/people}}');
                    }, ~/unopened section "people" at 21/i);
                });
            });

            describe('when invalid tags are given as an argument', function () {
                it('throws an error', function () {
                    throws(function () {
                        Mustache.parse('A template <% name %>', [ '<%' ]);
                    }, ~/invalid tags/i);
                });
            });

            describe('when the template contains invalid tags', function () {
                it('throws an error', function () {
                    throws(function () {
                        Mustache.parse('A template {{=<%=}}');
                    }, ~/invalid tags/i);
                });
            });

        });
    }
}
