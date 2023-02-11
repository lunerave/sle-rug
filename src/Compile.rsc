/* Sangrok Lee (s3279480), Siheon Lee (s2898373)  */
module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

/* Form -> HTML */
HTMLElement form2html(AForm f) {
  int idx1 = 0;
  list[HTMLElement] htmlInfo = [];
  list[HTMLElement] headInfo = [];
  list[HTMLElement] bodyInfo = [];
  
  // 1. Set up head parts (title, connect js file, using jQuery)
  HTMLElement jQueryScript = script([]);
  HTMLElement jsScript = script([]);
  jQueryScript.src = "https://code.jquery.com/jquery-3.6.3.js";
  jsScript.src = "<f.src[extension="js"].top.file>";
  headInfo += title([text("Questions - <f.name>")]);
  headInfo += jQueryScript;
  headInfo += jsScript;
  headInfo += style([text(".hidden { display : none }")]);

  // 2. Set up body parts (questions)
  for (AQuestion q <- f.questions) {
    bodyInfo += question2html(q, "<idx1>");
    idx1 = idx1+1;
  }

  htmlInfo += head(headInfo);
  htmlInfo += body(bodyInfo);
  return html(htmlInfo);
}

HTMLElement attribute2html(str wId, AType tp, bool editable) {
  HTMLElement result = input();
  result.id = "<wId>";
  result.class = "question";

  if (!editable) {
    result.disabled = "";
  }

  switch(tp) {
    case integer(): {
      result.\type = "number";
      result.\value = "0";
      result.step = "1";
    }
    case boolean(): {
      result.\type = "checkbox";
      result.\value = "";
    }
    case string(): {
      result.\type = "text";
      result.\value = "";
    }
    default: println("ERROR: Form can not be generated in attribute2html. ");
  }

  return result;
}

list[HTMLElement] question2html(AQuestion q, str index) {
  list[HTMLElement] questionInfo = [];
  switch(q) {
    case normalquestion(st(stringQuestion), ref(AId id), AType tp): {
      questionInfo += text(stringQuestion);
      questionInfo += attribute2html("q_<index>", tp, true);
      return [p(questionInfo)];
    }
    case computedquestion(st(stringQuestion), ref(AId id), AType tp, AExpr e): {
      questionInfo += text(stringQuestion);
      questionInfo += attribute2html("q_<index>", tp, false);
      return [p(questionInfo)];
    }
    case block(list[AQuestion] questions): {
      list[HTMLElement] blockList = [];
      int idx2 = 0;

      for (AQuestion question <- questions) {
        blockList += question2html(question, "<index>_<idx2>");
        idx2 += 1;
      }
      return blockList;
    }
    case question_if(AExpr cond, list[AQuestion] questions): {
      list[HTMLElement] ifList = [];
      int idx2 = 0;

      for (AQuestion question <- questions) {
        ifList += question2html(question, "<index>_<idx2>");
        idx2 += 1;
      }

      HTMLElement divBlock = div(ifList);
      divBlock.id = "if_q_<index>";
      return [divBlock];
    }
    case question_ifelse(AExpr cond, list[AQuestion] tquestions, list[AQuestion] fquestions): {
      list[HTMLElement] ifList = [];
      list[HTMLElement] elseList = [];
      list[HTMLElement] divBlocks = [];
      int idx2 = 0;

      for (AQuestion question <- tquestions) {
        ifList += question2html(question, "<index>_<idx2>");
        idx2 += 1;
      }

      for (AQuestion question <- fquestions) {
        elseList += question2html(question, "<index>_<idx2>");
        idx2 += 1;
      }

      HTMLElement divBlock1 = div(ifList);
      HTMLElement divBlock2 = div(elseList);
      divBlock1.id = "if_q_<index>";
      divBlock2.id = "else_q_<index>";

      divBlocks = [divBlock1] + [divBlock2];

      return divBlocks;
    }
    default: {
      return [text("ERROR: Error occured in question2html")];
    }
  }
}

/* Form -> Javascript */
str form2js(AForm f) {
  int idx = 0;
  return "$(\"document\").ready(function() {
         '  function update() {
         '    <for (AQuestion q <- f.questions) {>
         '      <question2js(q, "<idx>")>
         '    <idx += 1;}>
         '  }
         '
         '  function setHide(id, val) {
         '    if(val) {
         '      $(id).addClass(\"hidden\");
         '    } else {
         '      $(id).removeClass(\"hidden\");
         '    }
         '  }
         '
         '  $(\".question\").change(function() {
         '    update();
         '  });
         '
         '  update();
         '});  
         '";
}

/* For normal questions */
str setDefaultAttributeJs(str name, AType tp) {
  switch(tp) {
    case string(): {
      return "$(\"<name>\").val()";
    }
    case boolean(): {
      return "$(\"<name>\").is(\":checked\")";
    }
    case integer(): {
      return "$(\"<name>\").val()";
    }
    default: {
      return "/* ERROR: Error occured in setDefaultAttributeJs */";
    }
  }
}

/* For computed questions */
str setAttributeJs(str name, AType tp, str val) {
  switch(tp) {
    case string(): {
      return "$(\"<name>\").val(<val>)";
    }
    case boolean(): {
       return "$(\"<name>\").prop(\"checked\", <val>)";
    }
    case integer(): {
      return "$(\"<name>\").val(<val>)";
    }
    default: {
      return "/* ERROR: Error occured in setAttributeJs */";
    }
  }
}

str question2js(AQuestion q, str index) {
  switch (q) {
    case normalquestion(st(stringQuestion), ref(AId id), AType tp): {
      return "/* <stringQuestion> */
             '<id.name> = <setDefaultAttributeJs("#q_<index>", tp)>;";
    }
    case computedquestion(st(stringQuestion), ref(AId id), AType tp, AExpr e): {
      return "/* <stringQuestion> */
             '<id.name> = <expression2js(e)>;
             '<setAttributeJs("#q_<index>", tp, id.name)>;";
    }
    case block(list[AQuestion] questions): {
      int index2 = 0;

      return "<for (AQuestion question <- questions) {>
             '<question2js(question, "<index>_<index2>")><index2 += 1;}>";
    }
    case question_if(AExpr cond, list[AQuestion] questions): {
      int index2 = 0;
      return "if (<expression2js(cond)>) {
             '  setHide(\"#if_q_<index>\", false);
             '  <for (AQuestion question <- questions) {>
             '  <question2js(question, "<index>_<index2>")><index2 += 1;}>
             '} else {
             '  setHide(\"#if_q_<index>\", true);
             '}";
    }
    case question_ifelse(AExpr cond, list[AQuestion] tquestions, list[AQuestion] fquestions): {
      int index2 = 0;
      return "if (<expression2js(cond)>) {
             '  setHide(\"#if_q_<index>\", false);
             '  setHide(\"#else_q_<index>\", true);
             '  <for (AQuestion question <- tquestions) {>
             '  <question2js(question, "<index>_<index2>")><index2 += 1;}>
             '} else {
             '  setHide(\"#if_q_<index>\", true);
             '  setHide(\"#else_q_<index>\", false);
             '  <for (AQuestion question <- fquestions) {>
             '  <question2js(question, "<index>_<index2>")> <index2 += 1;}>
             '}";
    }
    default : return "/* ERROR: Error occured in question2js */";
  }
}

str expression2js(AExpr e) {
  switch (e) {
    case ref(id(str x)): return "<x>";
    case st(str s): return "<s>";   
    case number(int i): return "<i>";
    case bln(bool b): return "<b ? "true" : "false">";
    case not(AExpr e): return "(!<expression2js(e)>)";
    case mul(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> * <expression2js(rhs)>)";
    case div(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> / <expression2js(rhs)>)";
    case add(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> + <expression2js(rhs)>)";
    case sub(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> - <expression2js(rhs)>)";
    case ls(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> \< <expression2js(rhs)>)";
    case gr(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> \> <expression2js(rhs)>)";
    case leq(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> \<= <expression2js(rhs)>)";
    case geq(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> \>= <expression2js(rhs)>)";
    case equ(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> === <expression2js(rhs)>)";
    case neq(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> !== <expression2js(rhs)>)";   
    case and(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> && <expression2js(rhs)>)";   
    case or(AExpr lhs, AExpr rhs): return "(<expression2js(lhs)> || <expression2js(rhs)>)";   
    default: return "/* ERROR: Error occured in expression2js */";
  }
}

