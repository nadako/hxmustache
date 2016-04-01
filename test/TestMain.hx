class TestMain implements buddy.Buddy<[
    ScannerTest,
    ContextTest,
    ParseTest,
    #if (!flash && (!js || hxnodejs))
    TestSpec,
    #end
]> {}
