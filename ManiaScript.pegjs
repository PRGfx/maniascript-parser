{
  function makeFloat(digits, precision, s) {
    var f = s ? -1 : 1;
    return Number.parseFloat(
      digits.join("") + "." + precision.join(""),
      10
    ) * f;
  }

  function buildBinaryExpression(head, tail) {
    return tail.reduce(function(result, element) {
      return {
        type: "BinaryExpression",
        operator: element[1],
        left: result,
        right: element[3]
      };
    }, head);
  }

  function cleanupType(primary, arrays) {
    var type = { type: primary.value };
    if (arrays.length) {
      type.arrays = arrays.map(function(innerType) {
        if (innerType[1])
          return innerType[1].value;
        return "Void";
      });
    }
    return type;
  }
}

start
 = __ program:Program __ { return program; }

AsciiLetter
 = [a-zA-Z]

Digit
 = [0-9]

Char
 = .

LineTerminator
 = [\n\r]

Whitespace
 = [ \t]

__
 = (Whitespace / LineTerminator / Comment)*

EOF
 = !.

EOS
 = __ ";"
 / __ EOF

AsToken = "as"
BreakToken = "break"
CaseToken = "case"
CommandToken = "#Command"
ConstToken = "#Const"
ContinueToken = "continue"
DeclareToken = "declare"
DefaultToken = "default"
ElseToken = "else"
ExtendsToken = "#Extends"
FalseToken = "False"
ForeachToken = "foreach"
ForToken = "for"
IfToken = "if"
IncludeToken = "#Include"
InToken = "in"
IsToken = "is"
MainToken = "main"
NetreadToken = "netread"
NetwriteToken = "netwrite"
NullIdToken = "NullId"
NullToken = "Null"
PersistentToken = "persistent"
ReturnToken = "return"
RequireContextToken = "#RequireContext"
SettingToken = "#Setting"
SwitchToken = "switch"
SwitchTypeToken = "switchtype"
ThisToken = "This"
TrueToken = "True"
WhileToken = "while"
YieldToken = "yield"

Keyword
 = AsToken
 / BreakToken
 / CaseToken
 / CommandToken
 / ConstToken
 / ContinueToken
 / DeclareToken
 / DefaultToken
 / ElseToken
 / ExtendsToken
 / FalseToken
 / ForeachToken
 / ForToken
 / IfToken
 / IncludeToken
 / InToken
 / IsToken
 / MainToken
 / NetreadToken
 / NetwriteToken
 / NullIdToken
 / NullToken
 / PersistentToken
 / ReturnToken
 / RequireContextToken
 / SettingToken
 / SwitchToken
 / SwitchTypeToken
 / ThisToken
 / TrueToken
 / WhileToken
 / YieldToken

MultiLineComment
 = "/*" (!"*/" Char)* "*/"

SingleLineComment
 = "//" (!LineTerminator Char)*

Comment "comment"
 = MultiLineComment
 / SingleLineComment

Identifier
 = IdentifierStart IdentifierPart* { return { type: "Identifier", value: text() }; }

IdentifierStart
 = AsciiLetter
 / "_"

IdentifierPart
 = IdentifierStart
 / Digit

IdentifierName
 = $(!Keyword Identifier)

Integer
 = s:("-" __)? digits:Digit+ { return { type: "Integer", value: Number.parseInt(digits.join(""), 10) * (s?-1:1) }; }

Float
 = s:("-" __)? digits:Digit+ "." precision:Digit* { return { type: "Real", value: makeFloat(digits, precision, s) }; }
 / s:("-" __)? "." precision:Digit* { return { type: "Real", value: makeFloat([], precision, s) }; }

String
 = '"' chars:StringCharacter* '"' { return { type: "Text", value: chars.join("") }; }

StringCharacter
 = !('"' / "\\") Char { return text(); }
 / "\\" seq:StringEscapeSequence { return seq; }

StringEscapeSequence
 = '"'
 / "\\"
 / "n" { return "\n"; }
 / "t" { return "\t"; }
 / "r" { return "\r"; }

TemplateString
 = '"""' chars:TemplateStringCharacter* '"""' { return { type: "TemplateString", value: chars.join("") }; }

TemplateStringCharacter
 = !('"""') Char { return text(); }

BooleanLiteral
 = TrueToken { return { type: "Literal", value: true }; }
 / FalseToken { return { type: "Literal", value: false }; }

NullLiteral
 = NullIdToken { return { type: "Literal", value: null }; }
 / NullToken { return { type: "Literal", value: null }; }

Vec3
 = "<" __ x:Expression __ "," __ y:Expression __ "," __ z:Expression __ ">" { return { type: "Vec3", x: x, y: y, z: z }; }

Vec2
 = "<" __ x:Expression __ "," __ y:Expression __ ">" { return { type: "Vec2", x: x, y: y }; }

VectorLiteral
 = Vec2
 / Vec3

Array
 = "[" __ "]" { return { type: "Array", value: [] }; }
 / "[" __ head:Expression tail:ArrayTailElement* __ "]"
   { return { type: "Array", value: [head].concat(tail) }; }

ArrayTailElement
 = __ "," __ val:Expression { return val; }

AssocArray
 = "[" __ "]" { return { type: "AssocArray", value: {} }; }
 / "[" __ head:AssocArrayKeyValue tail:AssocArrayTailElement* __ "]"
   { return { type: "AssocArray", value: [head].concat(tail) }; }

AssocArrayTailElement
 = __ "," __ val:AssocArrayKeyValue { return val; }

AssocArrayKeyValue
 = k:Expression __ "=>" __ v:Expression { return { key: k, value: v }; }

EnumLiteral
 = ns:Identifier? "::" en:Identifier "::" v:Identifier
   { return { type: "EnumLiteral", namespace: ns || null, enum: en, value: v }; }

Literal
 = BooleanLiteral
 / NullLiteral
 / TemplateString
 / String
 / Float
 / Integer
 / VectorLiteral
 / Array
 / EnumLiteral
 / UnderscoreFunction

PrimaryExpression
 = ThisToken { return { type: "ThisExpression" }; }
 / Literal
 / Identifier
 / Array
 / AssocArray
 / "(" __ expression:Expression __ AsToken __ target:IdentifierName __ ")"
   { return { type: "TypeCast", from: expression, to: target }; }
 / "(" __ expression:Expression __ ")" { return expression; }

MemberExpression
 = head:PrimaryExpression tail:(
       __ "[" __ property:Expression __ "]" { return { property: property, member: false }; }
     / __ "." __ property:IdentifierName { return { property: property, member: true }; }
   )*
   {
     return (tail || []).reduce(function(result, element) {
      return {
        type: "MemberExpression",
        object: result,
        property: element.property,
        member: element.member
      };
     }, head);
   }

CallExpression
 = head:(
     callee:(LibraryCallee / MemberExpression) __ args:Arguments { return { type: "CallExpression", callee: callee, arguments: args }; }
   ) tail: (
       __ "[" property:Expression __ "]" { return { type: "MemberExpression", property: property, member: false }; }
     / __ "." property:Expression { return { type: "MemberExpression", property: property, member: true }; }
   )*
   {
     return tail.reduce(function(result, element) {
       element["object"] = result;
       return element;
     }, head);
   }

LibraryCallee
 = ns:Identifier "::" fn:Identifier { return { namespace: ns, method: fn }; }

Arguments
 = "(" __ ")" { return []; }
 / "(" __ head:Expression tail:ArgumentsList* __ ")"
   { return [head].concat(tail); }

ArgumentsList
 = __ "," __ arg:Expression { return arg; }

LeftSideExpression
 = CallExpression
 / MemberExpression

UnaryExpression
 = LeftSideExpression
 / op:UnaryOperator __ arg:UnaryExpression
   { return { type: "UnaryExpression", operator: op, argument: arg }; }

UnaryOperator
 = $("-" !"=")
 / $("+" !"=")
 / "!"

MultiplicativeExpression
 = head:UnaryExpression tail:(__ MultiplicativeOperator __ UnaryExpression)*
   { return buildBinaryExpression(head, tail); }

MultiplicativeOperator
 = $("*" !"=")
 / $("/" !"=")
 / "%"

AdditiveExpression
 = head:MultiplicativeExpression tail:(__ AdditiveOperator __ MultiplicativeExpression)*
   { return buildBinaryExpression(head, tail); }

AdditiveOperator
 = $("+" !"=")
 / $("-" !"=")
 / $("^" !"=")

RelationalExpression
 = head:AdditiveExpression tail:(__ RelationalOperator __ AdditiveExpression)*
   { return buildBinaryExpression(head, tail); }

RelationalOperator
 = $("<=" !">")
 / ">="
 / "<"
 / ">"
 / $IsToken

EqualityExpression
 = head:RelationalExpression tail:(__ EqualityOperator __ RelationalExpression)*
   { return buildBinaryExpression(head, tail); }
  
EqualityOperator
 = "=="
 / "!="

LogicalAndExpression
 = head:EqualityExpression tail:(__ LogicalAndOperator __ EqualityExpression)*
   { return buildBinaryExpression(head, tail); }

LogicalAndOperator
 = "&&"

LogicalOrExpression
 = head:LogicalAndExpression tail:(__ LogicalOrOperator __ LogicalAndExpression)*
   { return buildBinaryExpression(head, tail); }

LogicalOrOperator
 = "||"

AssignmentExpression
 = left:LeftSideExpression __
   ("=" !"=") __
   right:AssignmentExpression
   { return { type: "AssignmentExpression", left: left, right: right, operator: "=" }; }
 / left:LeftSideExpression __
   op:AssignmentOperator __
   right:AssignmentExpression
   { return { type: "AssignmentExpression", left: left, right: right, operator: op }; }
 / LogicalOrExpression

AssignmentOperator
 = "*="
 / "/="
 / "+="
 / "-="
 / "^="
 / "<=>"

UnderscoreFunction
 = "_" __ "(" __ value:(TemplateString / String) __ ")"

Expression
 = LogicalOrExpression
//  = LeftSideExpression



Statement
 = CodeBlock
 / VariableDeclaration
 / ForStatement
 / ForeachStatement
 / IfStatement
 / SwitchStatement
 / SwitchtypeStatement
 / FunctionCallStatement
 / WhileStatement
 / AssignmentStatement
 / ContinueStatement
 / BreakStatement
 / YieldStatement
 / ReturnStatement
 / LabelStatement

CodeBlock
 = "{" __ statements:(Statement __)* "}"
   { return statements.map(function(s) { return s[0]; }); }

IfStatement
 = IfBlock ElseIfBlock* __ ElseBlock?

IfBlock
 = IfToken __ "(" __ condition:Expression __ ")" __ body:Statement
   { return { type: "IfBlock", condition:condition, body:body } }

ElseIfBlock
 = __ ElseToken __ IfBlock

ElseBlock
 = ElseToken __ body:Statement { return { type: "ElseBlock", body:body } }

ForStatement
 = ForToken __ "(" __ variable:Identifier __ "," __ start:Expression __ "," __ end:Expression __ ")" __ body:Statement
   { return { type: "ForStatement", variable: variable, start: start, end: end, body: body }; }

ForeachStatement
 = ForeachToken __ "(" __ variable:Identifier __ (InToken / ",") __ array:Expression ")" __ body:Statement
   {return { type: "ForeachStatement", value: variable, key: null, array: array, body: body }; }
 / ForeachToken __ "(" __ variable:Identifier __ "=>" __ key:Identifier __ (InToken / ",") __ array:Expression ")" __ body:Statement
   {return { type: "ForeachStatement", value: variable, key: key, array: array, body: body }; }

WhileStatement
 = WhileToken __ "(" __ condition:Expression __ ")" __ body:Statement
   { return { type: "WhileStatement", condition: condition, body: body }; }

SwitchStatement
 = SwitchToken __ "(" __ variable:Expression __ ")" __ "{" cases:SwitchCase* __ "}"
   { return { type: "SwitchStatement", variable: variable, cases: cases }; }

SwitchtypeStatement
 = SwitchTypeToken __ "(" __ variable:Expression __ ")" __ "{" cases:SwitchCase* __ "}"
   { return { type: "SwitchtypeStatement", variable: variable, cases: cases }; }

SwitchCase
 = __ DefaultToken __ ":" __ body:Statement
   { return { type: "SwitchCase", condition: null, body: body }; }
 / __ CaseToken __ condition:Expression __ ":" __ body:Statement
   { return { type: "SwitchCase", condition: condition, body: body }; }

FunctionCallStatement
 = call:CallExpression EOS { return { type: "FunctionCall", callee: call.callee, arguments: call.arguments }; }

AssignmentStatement
 = assignment:AssignmentExpression EOS { return assignment; }

LabelStatement
 = "+++" __ name:IdentifierName __ "+++" { return { type: "Label", name: name, extends: true }; }
 / "---" __ name:IdentifierName __ "---" { return { type: "Label", name: name, extends: false }; }

LabelBlock
 = "***" __ name:IdentifierName __ "***" __ "***" __ body:FunctionCode* __ "***"
   { return { type: "LabelBlock", name: name, body: body.map(function(s) { return s[0]; }) }; }

YieldStatement
 = YieldToken EOS { return "YieldStatement" }

ContinueStatement
 = ContinueToken EOS { return "ContinueStatement" }

BreakStatement
 = BreakToken EOS { return "BreakStatement" }

ReturnStatement
 = ReturnToken __ value:Expression EOS { return { type: "ReturnStatement", value: value }; }

VariableDeclaration
 = DeclareToken __ modifier:(VariableModifier __)? type:(Type __) name:Identifier target:VariableDeclarationFor? assignment:VariableAssignment? EOS
   { return {
       modifier: modifier ? modifier[0] : null,
       type: type[0],
       name: name.value,
       target: target ? target.target : null,
       alias: target && target.alias ? target.alias.value : null,
       value: assignment
     };
   }
 / DeclareToken __ modifier:(VariableModifier __)? name:Identifier target:VariableDeclarationFor? assignment:VariableAssignment EOS
   { return {
       modifier: modifier ? modifier[0] : null,
       type: undefined,
       name: name.value,
       target: target ? target.target : null,
       alias: target && target.alias ? target.alias.value : null,
       value: assignment
     };
   }

VariableAssignment
 = __ op:("=" / "<=>") __ value:Expression
   { return { value: value, reference: op == "<=>", typeInitialization: false }; }
 / __ "=" __ value:Type
   { return { value: value, reference: false, typeInitialization: true }; }

VariableDeclarationFor
 = __ ForToken __ target:VariableDeclarationTarget alias:(__ AsToken __ name:Identifier)?
   { return { target: target, alias: alias ? alias[3] : null }; }

VariableDeclarationTarget
 = $(!Literal MemberExpression)
 / IdentifierName

VariableModifier
 = PersistentToken
 / NetreadToken
 / NetwriteToken

GlobalVariableDeclaration
 = DeclareToken __ type:Type __ name:Identifier EOS
   { return { type: "VariableDeclaration", name: name.value, variableType: type }; }

Type
 = primary:TypeClass arrays:("[" innerType:TypeClass? "]")*
   { return cleanupType(primary, arrays); }

TypeClass
 = ns:Identifier "::" member:Identifier { return { namespace: ns, member: member }; }
 / Identifier

FunctionDefinition
 = type:Type __ name:IdentifierName __ "(" __ args:FunctionDefinitionArguments? ")" __ "{" __ body:FunctionCode* __ "}"
   { return { type: "FunctionDefinition", name: name, returnType: type, arguments: args || [], body: body.map(function(s) { return s[0]; })}}

FunctionDefinitionArguments
 = head:FunctionDefinitionArgument __ tail:("," __ FunctionDefinitionArgument __)*
   { return tail.reduce(function(result, element) {
       result.push(element[2]);
       return result;
     }, [head]); }

FunctionDefinitionArgument
 = type:Type __ name:IdentifierName { return { type: type, name: name }; }

MainFunction
 = MainToken __ "(" __ ")" __ "{" __ body:FunctionCode* __ "}"
   { return { type: "MainFunction", body: body.map(function(s) { return s[0]; }) }; }

FunctionCode
 = Statement __
 / LabelStatement __

GlobalCode
 = FunctionDefinition
 / MainFunction
 / GlobalVariableDeclaration
 / LabelBlock

Constraint
 = IncludeToken __ lib:String __ alias:(AsToken __ name:IdentifierName __)?
   { return { type: "IncludeConstraint", library: lib.value, name: alias ? alias [2] : null }; }
 / ConstToken __ name:IdentifierName __ value:Literal __
   { return { type: "ConstConstraint", name: name, value: value }; }
 / SettingToken __ name:IdentifierName __ value:Literal __ AsToken __ label:(UnderscoreFunction / String) __
   { return { type: "SettingConstraint", name: name, value: value, label: label }; }
 / SettingToken __ name:IdentifierName __ value:Literal __
   { return { type: "SettingConstraint", name: name, value: value, label: null }; }
 / ExtendsToken __ lib:String __
   { return { type: "ExtendsConstraint", library: lib }; }
 / RequireContextToken __ ctx:Identifier __
   { return { type: "RequireContextConstraint", context: ctx }; }

Program
 = constraints:Constraint* statements:(__ GlobalCode)*
   { return {
       constraints: constraints,
       statements: statements? statements.map(function(s){return s[1];}) : []
     }; }
