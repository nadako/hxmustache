import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import utest.Assert;

typedef Spec = {
    tests:Array<{
        name:String,
        desc:String,
        data:{},
        template:String,
        ?partials:Dynamic,
        expected:String,
    }>
}

class TestSpec extends buddy.BuddySuite {
    static inline var specsDir = "spec/specs";

    static var specFiles = {
        var result = [];
        for (file in FileSystem.readDirectory(specsDir)) {
            var p = new haxe.io.Path(file);
            if (p.ext == "json" && p.file != "~lambdas")
                result.push(p.file);
        }
        result.push("inheritance");
        result;
    };

    var skipTests:haxe.DynamicAccess<Array<String>> = {
        comments: [
            'Standalone Without Newline'
        ],
        delimiters: [
            'Standalone Without Newline'
        ],
        inverted: [
            'Standalone Without Newline'
        ],
        partials: [
            'Standalone Without Previous Line',
            'Standalone Without Newline',
            'Standalone Indentation'
        ],
        sections: [
            'Standalone Without Newline'
        ],
        inheritance: [
            'Override partial with newlines'
        ]
    };

    static function getSpecs(specArea:String):Spec {
        var path = if (specArea == "inheritance") "test/inheritance.json" else '$specsDir/$specArea.json';
        return haxe.Json.parse(File.getContent(path));
    }

    public function new() {
        super();
        describe('Mustache spec compliance', function() {
            beforeEach(Mustache.clearCache());

            for (specArea in specFiles) {
                describe('- ' + specArea + ':', function() {
                    var specs = getSpecs(specArea);
                    for (test in specs.tests) {
                        var desc = test.name + ' - ' + test.desc;
                        if (skipTests.exists(specArea) && skipTests[specArea].indexOf(test.name) != -1)
                            xit(desc);
                        else
                            it(desc, function() {
                                var output = Mustache.render(test.template, new mustache.Context(test.data), test.partials);
                                Assert.equals(test.expected, output);
                            });
                    }
                });
            }
        });
    }
}
