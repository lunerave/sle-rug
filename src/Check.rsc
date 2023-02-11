/* Sangrok Lee (s3279480), Siheon Lee (s2898373)  */
module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

Type tpToType(AType tp) {
  switch(tp) {
		case integer(): return tint();
		case boolean(): return tbool();
		case string(): return tstr();
		default: return tunknown();
	}
} 
 

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  addQ = {};

  visit(f) {
    case normalquestion(st(str question), ref(AId id), AType tp, src = loc nq): addQ += <nq, id.name, "<question>", tpToType(tp)>;
    case computedquestion(st(str question), ref(AId id), AType tp, AExpr exp, src = loc cq): addQ += <cq, id.name, "<question>", tpToType(tp)>;
  }

  return addQ; 
}

// Error: duplicate question with different type.
set[Message] questionChecker(str question, AId id, Type t, AType tp, loc def){
  set[Message] msgs = {};
  if(question == id.name){
    if(tpToType(tp) != t){
      msgs += {error("duplicate question with different type", def)};
    }
  }
  return msgs;
}

// Warning: duplicate label.
set[Message] labelChecker(str label1, str label2, loc def1, loc def2){
  set[Message] msgs = {};
  if(label1 == label2 && def1 != def2){
    msgs += {warning("duplicate label", def1)};
  }
  return msgs;
}


set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  for(AQuestion q <- f.questions){
    msgs += check(q, tenv, useDef);
  }

  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch(q) {
    case normalquestion(st(qs), ref(AId id, src = loc u), AType tp, src = loc nq):
    {
      if(id.name in {"if", "else", "true", "false", "integer", "string", "boolean"}){
        msgs += {error("<id.name> is keyword", u)};
      }
      for(<loc def, str question, str label, Type t> <- tenv){
        if(def != nq){
          msgs += labelChecker(label, qs, def, nq);
          msgs += questionChecker(question, id, t, tp, def);
        }
      }
    }
    case computedquestion(st(qs), ref(AId id, src = loc u), AType tp, AExpr exp, src = loc cq):
    {
      if(id.name in {"if", "else", "true", "false", "integer", "string", "boolean"}){
        msgs += {error("<id.name> is keyworkd", u)};
      }
      for(<loc def, str question, str label, Type t> <- tenv){
        if(def != cq){
          msgs += labelChecker(label, qs, def, cq);
          msgs += questionChecker(question, id, t, tp, def);
        }else{
          msgs += check(exp, tenv, useDef);
          if(typeOf(exp, tenv, useDef) != t){
            msgs += {error("Declared question type and expression type does not match", exp.src)};
          }
        }
      }
    }
    case block(list[AQuestion] questions): 
    {
      for(AQuestion question <- q.questions){
        msgs += check(question, tenv, useDef);
      }
    }
    case question_ifelse(AExpr cond, list[AQuestion] tquestions, list[AQuestion] fquestions):
    {
      msgs += check(cond, tenv, useDef);
      if(typeOf(cond, tenv, useDef) != tbool()){
        msgs += {error("Condition is not boolean type", cond.src)};
      }
      //block of questions in if_then_else
      for(AQuestion question <- q.tquestions + q.fquestions){
        msgs += check(question, tenv, useDef);
      }
    }
    case question_if(AExpr cond, list[AQuestion] questions):
    {
      msgs += check(cond, tenv, useDef);
      if(typeOf(cond, tenv, useDef) != tbool()){
        msgs += {error("Condition is not boolean type", cond.src)};
      }
      //block of questions in if_then
      for(AQuestion question <- q.questions){
        msgs += check(question, tenv, useDef);
      }
    }
  }
  return msgs; 
}

// check operand compatibility with operators.
// Work for all expressions in set of expression. E.g. including rhs or lhs elements.
set[Message] exprChecker(set[AExpr] expr, set[Type] t, TEnv tenv, UseDef useDef, loc u){
  set[Message] msgs = {};

  for(AExpr e <- expr){
    msgs += check(e, tenv, useDef);
    if(!(typeOf(e, tenv, useDef) in t)){
      msgs += {error("types of elements in expression does not match", u)};
    }
  }
  return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case not(AExpr exp): 
      msgs += exprChecker({exp}, {tbool()}, tenv, useDef, exp.src);
    case add(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint()}, tenv, useDef, u);
    case sub(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint()}, tenv, useDef, u);
    case mul(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint()}, tenv, useDef, u);
    case div(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint()}, tenv, useDef, u);
    case gr(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint()}, tenv, useDef, u);
    case ls(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint()}, tenv, useDef, u);
    case leq(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint()}, tenv, useDef, u);
    case geq(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint()}, tenv, useDef, u);
    case equ(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint(), tbool(), tstr()}, tenv, useDef, u);
    case neq(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tint(), tbool(), tstr()}, tenv, useDef, u);
    case and(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tbool()}, tenv, useDef, u);
    case or(AExpr l, AExpr r, src = loc u):
      msgs += exprChecker({l, r}, {tbool()}, tenv, useDef, u);
  }
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case st(str s): return tstr();
    case bln(bool b): return tbool();
    case not(AExpr exp): return tbool();
    case add(AExpr lhs, AExpr rhs): return tint();
    case sub(AExpr lhs, AExpr rhs): return tint();
    case mul(AExpr lhs, AExpr rhs): return tint();
    case div(AExpr lhs, AExpr rhs): return tint();
    case gr(AExpr lhs, AExpr rhs): return tbool();
    case ls(AExpr lhs, AExpr rhs): return tbool();
    case leq(AExpr lhs, AExpr rhs): return tbool();
    case geq(AExpr lhs, AExpr rhs): return tbool();
    case equ(AExpr lhs, AExpr rhs): return tbool();
    case neq(AExpr lhs, AExpr rhs): return tbool();
    case and(AExpr lhs, AExpr rhs): return tbool();
    case or(AExpr lhs, AExpr rhs): return tbool();
    case number(int n): return tint();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */



