module CST2AST

import Syntax;
import AST;

import ParseTree;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("", [ ], src=f.src); 
}

AForm cst2ast(form:(Form)`form <Id m> { <Question* qs> }`) 
  = form("<m>", [cst2ast(q) | Question q <- qs], src = form@\loc);

AQuestion cst2ast(quest:(Question)`<NormalQuestion nq>`) 
  = nquestion(cst2ast(nq), src = quest@\loc);

AQuestion cst2ast(quest:(Question)`<ComputedQuestion cq>`)
  = cquestion(cst2ast(cq), src = quest@\loc);

AQuestion cst2ast(quest:(Question)`<Block block>`)
  = block(cst2ast(block), src = quest@\loc);

AQuestion cst2ast(quest:(Question)`if ( <Expr e> ) <Block block>`)
  = questionif(cst2ast(e), cst2ast(block), src = quest@\loc);

ANormalQuestion cst2ast(nquest:(NormalQuestion)`<Str s> <Id m> : <Type typ>`)
  = normalquestion("<s>", "<m>", cst2ast(typ), src = nquest@\loc);

AComputedQuestion cst2ast(cquest:(ComputedQuestion)`<Str s> <Id m> : <Type typ> = <Expr e>`)
  = computedquestion("<s>", "<m>", cst2ast(typ), cst2ast(e), src = cquest@\loc);

ABlock cst2ast(blck:(Block)`{ <Question* qs> }`)
  = block([cst2ast(q) | Question q <- qs], src = blck@\loc);

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x.src), src=x.src);
    case (ex:(Expr)`<Str s>`): return string("<s>", src = ex@\loc);
    case (ex:(Expr)`<Int i>`): return number("<i>", src = ex@\loc);
    case (ex:(Expr)`<Bool boo>`): return boolean("<boo>", src = ex@\loc);
    case (Expr)`( <Expr e> )`: return cst2ast(e);
    case (ex:(Expr)`!<Expr e>`): return not(cst2ast(e), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> + <Expr rhs>`): return add(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> - <Expr rhs>`): return sub(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> * <Expr rhs>`): return mul(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> / <Expr rhs>`): return div(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> \> <Expr rhs>`): return gr(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> \< <Expr rhs>`): return ls(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> \<= <Expr rhs>`): return leq(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> \>= <Expr rhs>`): return geq(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> == <Expr rhs>`): return eq(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> != <Expr rhs>`): return neq(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> && <Expr rhs>`): return and(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    case (ex:(Expr)`<Expr lhs> ||<Expr rhs>`): return or(cst2ast(lhs), cst2ast(rhs), src = ex@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(tp:(Type)`integer`) {
  typ(src = tp@\loc);
}

AType cst2ast(tp:(Type)`boolean`) {
  typ(src = tp@\loc);
}

AType cst2ast(tp:(Type)`string`) {
  typ(src = tp@\loc);
}
