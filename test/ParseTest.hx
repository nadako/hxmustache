import Assert.assert;

import mustache.Context;
import mustache.Token;

class ParseTest extends buddy.BuddySuite {

    public function new() {
        super();
        // A map of templates to their expected token output. Tokens are in the format:
        // [type, value, startIndex, endIndex, subTokens].
        var expectations:Map<String,Array<mustache.Token>> = [
            ''                                        => [],
            '{{hi}}'                                  => [ new Token( 'name', 'hi', 0, 6 ) ],
            '{{hi.world}}'                            => [ new Token( 'name', 'hi.world', 0, 12 ) ],
            '{{hi . world}}'                          => [ new Token( 'name', 'hi . world', 0, 14 ) ],
            '{{ hi}}'                                 => [ new Token( 'name', 'hi', 0, 7 ) ],
            '{{hi }}'                                 => [ new Token( 'name', 'hi', 0, 7 ) ],
            '{{ hi }}'                                => [ new Token( 'name', 'hi', 0, 8 ) ],
            '{{{hi}}}'                                => [ new Token( '&', 'hi', 0, 8 ) ],
            '{{!hi}}'                                 => [ new Token( '!', 'hi', 0, 7 ) ],
            '{{! hi}}'                                => [ new Token( '!', 'hi', 0, 8 ) ],
            '{{! hi }}'                               => [ new Token( '!', 'hi', 0, 9 ) ],
            '{{ !hi}}'                                => [ new Token( '!', 'hi', 0, 8 ) ],
            '{{ ! hi}}'                               => [ new Token( '!', 'hi', 0, 9 ) ],
            '{{ ! hi }}'                              => [ new Token( '!', 'hi', 0, 10 ) ],
            'a\n b'                                   => [ new Token( 'text', 'a\n b', 0, 4 ) ],
            'a{{hi}}'                                 => [ new Token( 'text', 'a', 0, 1 ), new Token( 'name', 'hi', 1, 7 ) ],
            'a {{hi}}'                                => [ new Token( 'text', 'a ', 0, 2 ), new Token( 'name', 'hi', 2, 8 ) ],
            ' a{{hi}}'                                => [ new Token( 'text', ' a', 0, 2 ), new Token( 'name', 'hi', 2, 8 ) ],
            ' a {{hi}}'                               => [ new Token( 'text', ' a ', 0, 3 ), new Token( 'name', 'hi', 3, 9 ) ],
            'a{{hi}}b'                                => [ new Token( 'text', 'a', 0, 1 ), new Token( 'name', 'hi', 1, 7 ), new Token( 'text', 'b', 7, 8 ) ],
            'a{{hi}} b'                               => [ new Token( 'text', 'a', 0, 1 ), new Token( 'name', 'hi', 1, 7 ), new Token( 'text', ' b', 7, 9 ) ],
            'a{{hi}}b '                               => [ new Token( 'text', 'a', 0, 1 ), new Token( 'name', 'hi', 1, 7 ), new Token( 'text', 'b ', 7, 9 ) ],
            'a\n{{hi}} b \n'                          => [ new Token( 'text', 'a\n', 0, 2 ), new Token( 'name', 'hi', 2, 8 ), new Token( 'text', ' b \n', 8, 12 ) ],
            'a\n {{hi}} \nb'                          => [ new Token( 'text', 'a\n ', 0, 3 ), new Token( 'name', 'hi', 3, 9 ), new Token( 'text', ' \nb', 9, 12 ) ],
            'a\n {{!hi}} \nb'                         => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '!', 'hi', 3, 10 ), new Token( 'text', 'b', 12, 13 ) ],
            'a\n{{#a}}{{/a}}\nb'                      => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 2, 8, [], 8 ), new Token( 'text', 'b', 15, 16 ) ],
            'a\n {{#a}}{{/a}}\nb'                     => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 3, 9, [], 9 ), new Token( 'text', 'b', 16, 17 ) ],
            'a\n {{#a}}{{/a}} \nb'                    => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 3, 9, [], 9 ), new Token( 'text', 'b', 17, 18 ) ],
            'a\n{{#a}}\n{{/a}}\nb'                    => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 2, 8, [], 9 ), new Token( 'text', 'b', 16, 17 ) ],
            'a\n {{#a}}\n{{/a}}\nb'                   => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 3, 9, [], 10 ), new Token( 'text', 'b', 17, 18 ) ],
            'a\n {{#a}}\n{{/a}} \nb'                  => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 3, 9, [], 10 ), new Token( 'text', 'b', 18, 19 ) ],
            'a\n{{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb'    => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 2, 8, [], 9 ), new Token( '#', 'b', 16, 22, [], 23 ),  new Token( 'text', 'b', 30, 31 ) ],
            'a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb'   => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 3, 9, [], 10 ), new Token( '#', 'b', 17, 23, [], 24 ), new Token( 'text', 'b', 31, 32 ) ],
            'a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}} \nb'  => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 3, 9, [], 10 ), new Token( '#', 'b', 17, 23, [], 24 ), new Token( 'text', 'b', 32, 33 ) ],
            'a\n{{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb'    => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 2, 8, [ new Token( '#', 'b', 9, 15, [], 16 ) ], 23 ),  new Token( 'text', 'b', 30, 31 ) ],
            'a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb'   => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 3, 9, [ new Token( '#', 'b', 10, 16, [], 17 ) ], 24 ), new Token( 'text', 'b', 31, 32 ) ],
            'a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}} \nb'  => [ new Token( 'text', 'a\n', 0, 2 ), new Token( '#', 'a', 3, 9, [ new Token( '#', 'b', 10, 16, [], 17 ) ], 24 ), new Token( 'text', 'b', 32, 33 ) ],
            '{{>abc}}'                                => [ new Token( '>', 'abc', 0, 8 ) ],
            '{{> abc }}'                              => [ new Token( '>', 'abc', 0, 10 ) ],
            '{{ > abc }}'                             => [ new Token( '>', 'abc', 0, 11 ) ],
            '{{=<% %>=}}'                             => [ new Token( '=', '<% %>', 0, 11 ) ],
            '{{= <% %> =}}'                           => [ new Token( '=', '<% %>', 0, 13 ) ],
            '{{=<% %>=}}<%={{ }}=%>'                  => [ new Token( '=', '<% %>', 0, 11 ), new Token( '=', '{{ }}', 11, 22 ) ],
            '{{=<% %>=}}<%hi%>'                       => [ new Token( '=', '<% %>', 0, 11 ), new Token( 'name', 'hi', 11, 17 ) ],
            '{{#a}}{{/a}}hi{{#b}}{{/b}}\n'            => [ new Token( '#', 'a', 0, 6, [], 6 ), new Token( 'text', 'hi', 12, 14 ), new Token( '#', 'b', 14, 20, [], 20 ), new Token( 'text', '\n', 26, 27 ) ],
            '{{a}}\n{{b}}\n\n{{#c}}\n{{/c}}\n'        => [ new Token( 'name', 'a', 0, 5 ), new Token( 'text', '\n', 5, 6 ), new Token( 'name', 'b', 6, 11 ), new Token( 'text', '\n\n', 11, 13 ), new Token( '#', 'c', 13, 19, [], 20 ) ],
            '{{#foo}}\n  {{#a}}\n    {{b}}\n  {{/a}}\n{{/foo}}\n' => [
                new Token( '#', 'foo', 0, 8, [ new Token( '#', 'a', 11, 17, [ new Token( 'text', '    ', 18, 22 ), new Token( 'name', 'b', 22, 27 ), new Token( 'text', '\n', 27, 28 ) ], 30 ) ], 37 )
            ]
        ];

        describe('Mustache.parse', function () {

            for (template in expectations.keys()) {
                (function (template, tokens) {
                    it('knows how to parse ' + haxe.Json.stringify(template), function () {
                        assert.deepEqual(Mustache.parse(template), tokens);
                    });
                })(template, expectations[template]);
            }

            describe('when there is an unclosed tag', function () {
                it('throws an error', function () {
                    assert.throws(function () {
                        Mustache.parse('My name is {{name');
                    }, ~/unclosed tag at 17/i);
                });
            });

            describe('when there is an unclosed section', function () {
                it('throws an error', function () {
                    assert.throws(function () {
                        Mustache.parse('A list: {{#people}}{{name}}');
                    }, ~/unclosed section "people" at 27/i);
                });
            });

            describe('when there is an unopened section', function () {
                it('throws an error', function () {
                    assert.throws(function () {
                        Mustache.parse('The end of the list! {{/people}}');
                    }, ~/unopened section "people" at 21/i);
                });
            });

            describe('when invalid tags are given as an argument', function () {
                it('throws an error', function () {
                    assert.throws(function () {
                        Mustache.parse('A template <% name %>', [ '<%' ]);
                    }, ~/invalid tags/i);
                });
            });

            describe('when the template contains invalid tags', function () {
                it('throws an error', function () {
                    assert.throws(function () {
                        Mustache.parse('A template {{=<%=}}');
                    }, ~/invalid tags/i);
                });
            });

        });
    }
}
