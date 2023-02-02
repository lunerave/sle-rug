module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

/* keyword? */
keyword MyKeywords = "if" | "else" | "true" | "false" | "integer" | "string" | "boolean" ;

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question 
  = normalquestion: Str question Id name ":" Type tp // Normal Question
  | computedquestion: Str question Id name ":" Type tp "=" Expr exp // Computed Question
  | block: "{" Question* questions "}"
  | question_ifelse: "if" "(" Expr cond ")" "{" Question* tquestions "}" "else" "{" Question* fquestions "}" //true then questions && false then questions
  | question_if: "if" "(" Expr cond ")" "{" Question* questions "}"
  ;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false"
  | st: Str s
  | number: Int n
  | bln: Bool b
  | bracket brck: "(" Expr e ")"
  > right not: "!" Expr exp
  > left mul: Expr lhs "*" Expr rhs
  > left div: Expr lhs "/" Expr rhs
  > left add: Expr lhs "+" Expr rhs
  > left sub: Expr lhs "-" Expr rhs 
  > left gr: Expr lhs "\>" Expr rhs
  > left ls: Expr lhs "\<" Expr rhs
  > left leq: Expr lhs "\<=" Expr rhs
  > left geq: Expr lhs "\>=" Expr rhs
  > left eq: Expr lhs "==" Expr rhs
  > left neq: Expr lhs "!=" Expr rhs
  > left and: Expr lhs "&&" Expr rhs
  > left or: Expr lhs "||" Expr rhs
  ;
  
syntax Type 
 = "integer"
 | "boolean"
 | "string"
 ;

lexical Str = "\"" ![\"]*  "\"";

lexical Int 
  = [0-9]+;

lexical Bool = "true" | "false";




