/* Sangrok Lee (s3279480), Siheon Lee (s2898373)  */
module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  firstVenv = ();
    visit(f) {
      case normalquestion(st(str question), ref(AId id), AType tp, src = loc nq):
        firstVenv += ("<id.name>": setDefaultValue(tp));
      case computedquestion(st(str question), ref(AId id), AType tp, AExpr exp, src = loc cq):
        firstVenv += ("<id.name>": setDefaultValue(tp));
    }
    return firstVenv;
}

Value setDefaultValue(AType tp) {
  switch(tp) {
    case integer():
      return vint(0);
    case boolean():
      return vbool(false);
    case string():
      return vstr("");
    default:
      return vint(0);
  }
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  visit(f) {
    case AQuestion q: venv = eval(q, inp, venv);
  }
  return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch(q) {
    case normalquestion(AExpr question, ref(AId id), AType tp): {
      if (q.question.s[1..-1] == inp.question) {
        venv[id.name] = inp.\value; // evaluate venv with input
      }
    }
    case computedquestion(AExpr question, ref(AId id), AType tp,  AExpr e): {
      venv[id.name] = eval(e, venv); // evaluate venv with computed result
    }
    case block(list[AQuestion] questions): {
      for (AQuestion question <- questions) {
        eval(question, inp, venv); 
      }
    }
    case question_if(AExpr cond, list[AQuestion] questions): {
      if (eval(cond, venv) == vbool(true)) {
        for (AQuestion question <- questions) {
          eval(question, inp, venv); 
        }
      }
    }
    case question_ifelse(AExpr cond, list[AQuestion] tquestions, list[AQuestion] fquestions): {
      if (eval(cond, venv) == vbool(true)) {
        for (AQuestion question <- tquestions) {
          eval(question, inp, venv); 
        }
      } else {
        for (AQuestion question <- fquestions) {
          eval(question, inp, venv); 
        }
      }
    }
  }
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case number(int n): return vint(n);
    case bln(bool b):  return vbool(b);
    case st(str s):  return vstr(s[1..-1]);
    case not(AExpr e): return vbool(!eval(e, venv).b); 
    case add(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case sub(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case mul(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case gr(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case ls(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case leq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    case geq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    case equ(AExpr lhs, AExpr rhs): {
        lVal = eval(lhs, venv);
        rVal = eval(rhs, venv);
        switch(lVal) {
          case vint(int ln): {
            switch(rVal) {
              case vint(rn): return vbool(ln == rn);
              default: return vbool(false);
            }
          }
          case vbool(bool lb): {
            switch(rVal) {
              case vbool(rb): return vbool(lb == rb);
              default: return vbool(false);
            }
          }
          case vstr(str ls): {
            switch(rVal) {
              case vstr(rs): return vbool(ls == rs);
              default: return vbool(false);
            }
          }
          default: return vbool(false);
        }
      }
    case neq(AExpr lhs, AExpr rhs): {
        lVal = eval(lhs, venv);
        rVal = eval(rhs, venv);
        switch(lVal) {
          case vint(int ln): {
            switch(rVal) {
              case vint(rn): return vbool(ln != rn);
              default: return vbool(true);
            }

          }
          case vbool(bool lb): {
            switch(rVal) {
              case vbool(rb): return vbool(lb != rb);
              default: return vbool(true);
            }
          }
          case vstr(str ls): {
            switch(rVal) {
              case vstr(rs): return vbool(ls != rs);
              default: return vbool(true);
            }
          }
          default: return vbool(true);
        }
      }
    default: throw "Unsupported expression <e>";
  }
}