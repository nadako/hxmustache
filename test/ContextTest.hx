import Assert.assert;
using buddy.Should;

import mustache.Context;

class ContextTest extends buddy.BuddySuite {
    public function new() {
        super();
        describe('A new Mustache.Context', function () {
            var context;
            beforeEach(function () {
                context = new Context({ name: 'parent', message: 'hi', a: { b: 'b' } });
            });

            it('is able to lookup properties of its own view', function () {
                assert.equal(context.lookup('name'), 'parent');
            });

            it('is able to lookup nested properties of its own view', function () {
                assert.equal(context.lookup('a.b'), 'b');
            });

            describe('when pushed', function () {
                beforeEach(function () {
                    context = context.push({ name: 'child', c: { d: 'd' } });
                });

                it('returns the child context', function () {
                    assert.equal((untyped context.view.name : String), 'child');
                    assert.equal((untyped context.parent.view.name : String), 'parent');
                });

                it('is able to lookup properties of its own view', function () {
                    assert.equal(context.lookup('name'), 'child');
                });

                it("is able to lookup properties of the parent context's view", function () {
                    assert.equal(context.lookup('message'), 'hi');
                });

                it('is able to lookup nested properties of its own view', function () {
                    assert.equal(context.lookup('c.d'), 'd');
                });

                it('is able to lookup nested properties of its parent view', function () {
                    assert.equal(context.lookup('a.b'), 'b');
                });
            });
        });
    }
}