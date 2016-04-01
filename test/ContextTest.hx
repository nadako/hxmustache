import utest.Assert;

class ContextTest extends buddy.BuddySuite {
    public function new() {
        super();
        describe('A new Mustache.Context', function () {
            var context;
            beforeEach(function () {
                context = new mustache.Context({ name: 'parent', message: 'hi', a: { b: 'b' } });
            });

            it('is able to lookup properties of its own view', function () {
                Assert.equals('parent', context.lookup('name'));
            });

            it('is able to lookup nested properties of its own view', function () {
                Assert.equals('b', context.lookup('a.b'));
            });

            describe('when pushed', function () {
                beforeEach(function () {
                    context = context.push({ name: 'child', c: { d: 'd' } });
                });

                it('returns the child context', function () {
                    Assert.equals('child', context.view.name);
                    Assert.equals('parent', context.parent.view.name);
                });

                it('is able to lookup properties of its own view', function () {
                    Assert.equals('child', context.lookup('name'));
                });

                it("is able to lookup properties of the parent context's view", function () {
                    Assert.equals('hi', context.lookup('message'));
                });

                it('is able to lookup nested properties of its own view', function () {
                    Assert.equals('d', context.lookup('c.d'));
                });

                it('is able to lookup nested properties of its parent view', function () {
                    Assert.equals('b', context.lookup('a.b'));
                });
            });
        });
    }
}