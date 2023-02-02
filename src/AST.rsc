module AST

import Syntax;
import ParseTree;

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = normalquestion(AExpr question, AExpr name, AType tp) 
  | computedquestion(AExpr question, AExpr name, AType tp, AExpr exp)
  | block(list[AQuestion] questions)
  | question_ifelse(AExpr cond, list[AQuestion] tquestions, list[AQuestion] fquestions)
  | question_if(AExpr cond, list[AQuestion] questions) 
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | st(str s)
  | number(int n)
  | bln(bool b)
  | brck(AExpr exp)
  | not(AExpr exp)
  | add(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | gr(AExpr lhs, AExpr rhs)
  | ls(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;


data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = integer()
  | boolean()
  | string()
  ;