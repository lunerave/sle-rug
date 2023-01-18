module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

/* keyword? */
keyword MyKeywords = "if" | "else" | "true" | "false" | "integer" | "string" | "boolean" ;

start syntax Form 
  = "form" Id \ MyKeywords name "{" Question* questions "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question 
  = NormalQuestion
  | ComputedQuestion
  | Block
  | "if" "(" Expr ")" Block ("else" Block)?
  ;


syntax NormalQuestion = Str Id \ MyKeywords ":" Type ;

syntax ComputedQuestion = Str Id \ MyKeywords ":" Type "=" Expr ;

syntax Block = "{" Question* questions "}";

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ MyKeywords // true/false are reserved keywords.
  | Str
  | Int
  | Bool
  | bracket "(" Expr ")"
  > right "!" Expr
  > left ( mul: Expr l "*" Expr r
         | div: Expr l "/" Expr r
         )
  > left ( add: Expr l "+" Expr r
         | sub: Expr l "-" Expr r 
         )
  > left ( gr: Expr l "\>" Expr r
         | ls: Expr l "\<" Expr r
         | leq: Expr l "\<=" Expr r
         | geq: Expr l "\>=" Expr r
         )
  > left ( eq: Expr l "==" Expr r
         | neq: Expr l "!=" Expr r
         )
  > left ( and: Expr l "&&" Expr r
         | or: Expr l "||" Expr r
         )
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



