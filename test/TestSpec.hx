import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import utest.Assert;

typedef Spec = {
    tests:Array<{
        name:String,
        desc:String,
        data: {
            ?lambda:{__tag__:String}
        },
        template:String,
        partials:Dynamic,
        expected:String,
    }>
}

class TestSpec extends buddy.BuddySuite {
    static inline var specsDir = "spec/specs";

    static var specFiles = {
        var result = [];
        for (file in FileSystem.readDirectory(specsDir)) {
            var p = new haxe.io.Path(file);
            if (p.ext == "json")
                result.push(p.file);
        }
        result;
    };

    static inline function getSpecs(specArea:String):Spec {
        return haxe.Json.parse(File.getContent('$specsDir/$specArea.json'));
    }

    public function new() {
        super();
        describe('Mustache spec compliance', function() {
            beforeEach(Mustache.clearCache());

            for (specArea in specFiles) {
                describe('- ' + specArea + ':', function() {
                    var specs = getSpecs(specArea);
                    for (test in specs.tests) {
                        it(test.name + ' - ' + test.desc, function() {
                            if (test.data.lambda != null && test.data.lambda.__tag__ == 'code')
                                return;// test.data.lambda = eval('(function() { return ' + test.data.lambda.js + '; })');
                            var output = Mustache.render(test.template, new mustache.Context(test.data), test.partials);
                            Assert.equals(test.expected, output);
                        });
                    }
                });
            }
        });
    }
}
