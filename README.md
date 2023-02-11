## Concrete Syntax, Abstract Syntax
    import Syntax;
    import ParseTree;
    start[Form] Form1 = parse(#start[Form], |project://sle-rug/examples/tax.myql|); 
    import AST;
    import CST2AST;
    ast1 = cst2ast(Form1);

## Type Check
    import Resolve;
    g = resolve(ast1);
    import Check;
    tenv1 = collect(ast1);
    check(ast1, tenv1, g.useDef);

    start[Form] Form2 = parse(#start[Form], |project://sle-rug/examples/errors.myql|);
    ast2 = cst2ast(Form2);
    tenv2 = collect(ast2);
    check(ast2, tenv2, g.useDef);

## Intepretation
    import Eval;
    start[Form] Form3 = parse(#start[Form], |project://sle-rug/examples/testEval.myql|); 
    ast3 = cst2ast(Form3);
    venv = initialEnv(ast3);
    eval(ast3, input("Normal Question - int", vint(320)), venv);

## Code generation (HTML, JS)
    import Compile;
    start[Form] Form4 = parse(#start[Form], |project://sle-rug/examples/testCompile.myql|); 
    ast4 = cst2ast(Form4);
    compile(ast4); 

## Transformation
    import Transform;
    start[Form] Form5 = parse(#start[Form], |project://sle-rug/examples/binary.myql|); 
    ast5 = cst2ast(Form5);
    flatForm = flatten(ast5);
    flatForm.src = Form5.src.top;
    compile(flatForm);

