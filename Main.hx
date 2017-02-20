import js.html.*;
import js.Browser.document;

class Main {
    static function main() {
        var dataTextArea:TextAreaElement = cast document.getElementById("data");
        var templateTextArea:TextAreaElement = cast document.getElementById("template");
        var resultCode:Element = cast document.getElementById("result");
        var dataErrorSpan:SpanElement = cast document.getElementById("data-error");
        var templateErrorSpan:SpanElement = cast document.getElementById("template-error");

        function render() {
            var template = templateTextArea.value;
            // resultCode.innerText = "";
            dataErrorSpan.textContent = "";
            templateErrorSpan.textContent = "";
            var data:{} =
                if (StringTools.trim(dataTextArea.value).length == 0)
                    {}
                else
                    try {
                        haxe.Json.parse(dataTextArea.value);
                    } catch (e:Dynamic) {
                        dataErrorSpan.textContent = ' (ERROR: $e)';
                        return;
                    }
            resultCode.innerText =
                try {
                    Mustache.render(template, data);
                } catch (e:Dynamic) {
                    templateErrorSpan.textContent = ' (ERROR: $e)';
                    return;
                }
            (untyped hljs).highlightBlock(resultCode);
        }

        dataTextArea.oninput = dataTextArea.oninput = render;
        templateTextArea.oninput = templateTextArea.oninput = render;
        render();
    }
}
