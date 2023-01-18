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
  = nquestion(ANormalQuestion anq)
  | cquestion(AComputedQuestion acq)
  | block(ABlock ablock)
  | ifelse(AExpr arg, ABlock ablock, ABlock ablock) //어케하지
  ; 

data ANormalQuestion(loc src = |tmp:///|)
  = normalquestion(str question, str name, AType tp) ;

data AComputedQuestion(loc src = |tmp:///|) 
  = computedquestion(str question, str name, AType tp, AExpr exp);

data ABlock(loc src = |tmp:///|) 
  = block(list[AQuestion] questions);

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | string(str string)
  | number(int number)
  | boolean(bool boolean)
  | not(AExpr arg)
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
  = tp();