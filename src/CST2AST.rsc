/* Sangrok Lee (s3279480), Siheon Lee (s2898373)  */
module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;


/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) 
{
  Form f = sf.top; // remove layout before and after form
  return form("<f.name>", [cst2ast(q) | Question q <- f.questions], src=f@\loc); 
}

AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str question> <Id name> : <Type tp>`: return normalquestion(cst2ast((Expr)`<Str question>`), cst2ast((Expr)`<Id name>`), cst2ast(tp), src=q@\loc);
    case (Question)`<Str question> <Id name> : <Type tp> = <Expr exp>`: return computedquestion(cst2ast((Expr)`<Str question>`), cst2ast((Expr)`<Id name>`), cst2ast(tp), cst2ast(exp), src=q@\loc);
    case (Question)`{ <Question* questions> }`: return block([cst2ast(q) | Question q <- questions], src=q@\loc);
    case (Question)`if (<Expr cond>) { <Question* tquestions> } else { <Question* fquestions> }`: return question_ifelse(cst2ast(cond), [cst2ast(q) | Question q <- tquestions], [cst2ast(q) | Question q <- fquestions], src=q@\loc);
    case (Question)`if (<Expr cond>) { <Question* questions> }`: return question_if(cst2ast(cond), [cst2ast(q) | Question q <- questions], src=q@\loc);
    
    default:
      throw "Not yet implemented <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x@\src), src=x@\src);
    case (Expr)`(<Expr x>)`: return cst2ast(x);
    case (Expr)`<Expr l> * <Expr r>`: return mul(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`!<Expr exp>`: return not(cst2ast(exp), src = exp@\loc);
    case (Expr)`<Expr l> + <Expr r>`: return add(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> - <Expr r>`: return sub(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> / <Expr r>`: return div(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> \> <Expr r>`: return gr(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> \< <Expr r>`: return ls(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> \<= <Expr r>`: return leq(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> \>= <Expr r>`: return geq(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> == <Expr r>`: return equ(cst2ast(l), cst2ast(r), src=e@\loc);
    case (Expr)`<Expr l> != <Expr r>`: return neq(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> && <Expr r>`: return and(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Expr l> || <Expr r>`: return or(cst2ast(l), cst2ast(r), src = e@\loc);
    case (Expr)`<Bool b>`: return bln(fromString("<b>"), src = b@\loc);
    case (Expr)`<Int n>`: return number(toInt("<n>"), src = n@\loc);
    case (Expr)`<Str s>`: return st("<s>", src = s@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type tp) {
  switch (tp) {
    case (Type)`integer`: return integer(src=tp@\loc);
    case (Type)`boolean`: return boolean(src=tp@\loc);
    case (Type)`string`: return string(src=tp@\loc);

    default: throw "Unhandled type: <tp>";
  }
}

