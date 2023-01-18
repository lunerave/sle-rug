module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  return { <e.id.src, e.id.name> | /AExpr e := f}; 
}

Def defs(AForm f) {
  return { <nq.name, nq.src> | /ANormalQuestion nq := f} + { <cq.name, cq.src> | /AComputedQuestion cq := f}; 
}