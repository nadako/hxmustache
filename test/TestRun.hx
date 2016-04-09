import utest.Assert;

class TestRun extends buddy.BuddySuite {
    public function new() {
        super();
        describe("haxelib run hxmustache", function() {
            it("should render using given arguments", function() {
                var args = [
                    "run",
                    "hxmustache",
                    "test/test_view.json",
                    "test/test_template.mustache",
                    "-p", "test/test_layout.mustache"
                ];
                var proc = new sys.io.Process("haxelib", args);
                var exitCode = proc.exitCode();
                var stdout = StringTools.replace(proc.stdout.readAll().toString(), "\r\n", "\n");
                var expected = sys.io.File.getContent("test/test_expected.html");
                Assert.equals(0, exitCode);
                Assert.equals(expected, stdout);
            });
            it("should render to file using given arguments", function() {
                var args = [
                    "run",
                    "hxmustache",
                    "test/test_view.json",
                    "test/test_template.mustache",
                    "-p", "test/test_layout.mustache",
                    "test/test_output.html"
                ];
                var proc = new sys.io.Process("haxelib", args);
                var exitCode = proc.exitCode();
                var stdout = StringTools.replace(proc.stdout.readAll().toString(), "\r\n", "\n");
                var expected = sys.io.File.getContent("test/test_expected.html");
                var actual = sys.io.File.getContent("test/test_output.html");
                Assert.equals(0, exitCode);
                Assert.equals(expected, actual);
                Assert.equals("", stdout);
            });
        });
    }
}
