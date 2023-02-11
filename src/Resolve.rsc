/* Sangrok Lee (s3279480), Siheon Lee (s2898373)  */
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

// use from ID in Expr
Use uses(AForm f) {
	return {<r.src, id.name> | /r:ref(AId id, src = loc u) := f};
}

// def from ID in normal question or computed question
Def defs(AForm f) {
	return {<id.name, nq.src> | /nq:normalquestion(AExpr question, ref(AId id, src = loc u), AType tp):=f} 
		 + {<id.name, cq.src> | /cq:computedquestion(AExpr question, ref(AId id, src = loc u), AType tp, AExpr exp):=f};
}