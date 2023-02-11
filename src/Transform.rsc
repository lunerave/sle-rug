module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */

AForm flatten(AForm f) {
  list[AQuestion] flatQuestions = [];

  for(AQuestion q <- f.questions){
    flatQuestions += flatten(q, bln(true));
  }
  AForm fForm = form(f.name, flatQuestions);

  return fForm; 
}

list[AQuestion] flatten(AQuestion q, AExpr bln){
  list[AQuestion] flatQuestions = [];
  switch(q) {
    case normalquestion(st(question), ref(AId id), AType tp, src = loc nq): flatQuestions += question_if(bln, [q]);
    case computedquestion(st(question), ref(AId id), AType tp, AExpr exp, src = loc cq): flatQuestions += question_if(bln, [q]);
    case block(list[AQuestion] questions):
    {
      for(AQuestion question <- questions){
        flatQuestions += flatten(question, bln);
      }
    }
    case question_ifelse(AExpr cond, list[AQuestion] tquestions, list[AQuestion] fquestions):
    {
      for(AQuestion question <- tquestions){
        flatQuestions += flatten(question, and(cond, bln));
      }
      for(AQuestion question <- fquestions){
        flatQuestions += flatten(question, and(not(cond), bln));
      }
    }
    case question_if(AExpr cond, list[AQuestion] questions):
    {
      for(AQuestion question <- questions){
        flatQuestions += flatten(question, and(cond, bln));
      }
    }
  }
  return flatQuestions;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {

  RefGraph r = resolve(cst2ast(f));

  set[loc] toRename = {};

  if(useOrDef in r.defs<1>){
    toRename += {useOrDef};
    toRename += {u | <loc u, useOrDef> <- r.useDef};
  }else if(useOrDef in r.uses<0>){
    if(<useOrDef, loc d> <- r.useDef){
      toRename += {u | <loc u, d> <- r.useDef};
    }
  }else{
    return f;
  }

  return visit (f) {
    case Id x => [Id]newName
    when x@\src in toRename
  }
} 

 