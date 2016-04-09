package mustache;

class Run {
    static function main() {
        var args = Sys.args();

        if (Sys.getEnv("HAXELIB_RUN") != null)
            Sys.setCwd(args.pop());

        try {
            var partialIdx = -1;
            var partialPaths = [];
            while ((partialIdx = args.indexOf("-p")) != -1) {
                var parts = args.splice(partialIdx, 2);
                if (parts.length < 2)
                    throw "Missing filename for `-p` argument";
                partialPaths.push(parts[1]);
            }

            if (args.length < 2)
                usage();

            var viewFile = args[0];
            var viewContent = try sys.io.File.getContent(viewFile) catch(e:Dynamic) throw 'Cannot open view `$viewFile`';
            var view:{} = try haxe.Json.parse(viewContent) catch (e:Dynamic) throw 'Cannot parse view `$viewFile`: $e';

            var templateFile = args[1];
            var templateContent = try sys.io.File.getContent(templateFile) catch(e:Dynamic) throw 'Cannot open template `$templateFile`';
            try Mustache.parse(templateContent) catch (e:Dynamic) throw 'Cannot parse template `$templateFile`: $e';

            var partials = new haxe.DynamicAccess();
            for (path in partialPaths) {
                var partialContent = try sys.io.File.getContent(path) catch(e:Dynamic) throw 'Cannot open partial `$path`';
                try Mustache.parse(partialContent) catch (e:Dynamic) throw 'Cannot parse partial `$path`: $e';
                var p = new haxe.io.Path(path);
                partials[p.file] = partialContent;
            }

            var output = Mustache.render(templateContent, view, partials);
            var outputFile = args[2];
            if (outputFile == null)
                Sys.print(output);
            else
                sys.io.File.saveContent(outputFile, output);
        } catch (e:Dynamic) {
            Sys.println('ERROR: $e');
            Sys.exit(1);
        }
    }

    static function usage() {
        Sys.println("Usage: haxelib run hxmustache <view.json> <template.mustache> [-p partial.mustache]* [output]");
        Sys.exit(1);
    }
}
