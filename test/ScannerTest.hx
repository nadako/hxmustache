import utest.Assert;
import mustache.Scanner;

class ScannerTest extends buddy.BuddySuite {
    public function new() {
        super();
        describe('A new Mustache.Scanner', function () {
            describe('for an empty string', function () {
                it('is at the end', function () {
                    var scanner = new Scanner('');
                    Assert.isTrue(scanner.eos());
                });
            });

            describe('for a non-empty string', function () {
                var scanner;
                beforeEach(function () {
                    scanner = new Scanner('a b c');
                });

                describe('scan', function () {
                    describe('when the RegExp matches the entire string', function () {
                        it('returns the entire string', function () {
                            var match = scanner.scan(~/a b c/);
                            Assert.equals(scanner.string, match);
                            Assert.isTrue(scanner.eos());
                        });
                    });

                    describe('when the RegExp matches at index 0', function () {
                        it('returns the portion of the string that matched', function () {
                            var match = scanner.scan(~/a/);
                            Assert.equals('a', match);
                            Assert.equals(1, scanner.pos);
                        });
                    });

                    describe('when the RegExp matches at some index other than 0', function () {
                        it('returns the empty string', function () {
                            var match = scanner.scan(~/b/);
                            Assert.equals('', match);
                            Assert.equals(0, scanner.pos);
                        });
                    });

                    describe('when the RegExp does not match', function () {
                        it('returns the empty string', function () {
                            var match = scanner.scan(~/z/);
                            Assert.equals('', match);
                            Assert.equals(0, scanner.pos);
                        });
                    });
                }); // scan

                describe('scanUntil', function () {
                    describe('when the RegExp matches at index 0', function () {
                        it('returns the empty string', function () {
                            var match = scanner.scanUntil(~/a/);
                            Assert.equals('', match);
                            Assert.equals(0, scanner.pos);
                        });
                    });

                    describe('when the RegExp matches at some index other than 0', function () {
                        it('returns the string up to that index', function () {
                            var match = scanner.scanUntil(~/b/);
                            Assert.equals('a ', match);
                            Assert.equals(2, scanner.pos);
                        });
                    });

                    describe('when the RegExp does not match', function () {
                        it('returns the entire string', function () {
                            var match = scanner.scanUntil(~/z/);
                            Assert.equals(scanner.string, match);
                            Assert.isTrue(scanner.eos());
                        });
                    });
                }); // scanUntil
            }); // for a non-empty string
        });

    }
}
