{
  // Función auxiliar para convertir cadenas con escapes
  function unescapeString(str) {
    return JSON.parse(str);
  }
}

Start
  = sentence:Sentence { return sentence; }

Sentence = Value

Value = Value_appended

Value_appended =
  value:Value_pure
  appends:Value_appendment*
    { return { $type:"value", value, appends } }

Value_pure = Json_value

Value_appendment = Subsentence_return / Subsentence_export / Subsentence_filter / Subsentence_multiply

Injected_parameter = "#" (Js_noun / Integer)? { return { $type: "injected parameter", value: text() } }

Select_group = 
  token1:(_)
  table:Table_name
  filters:Where_filters_precolons?
  token2:(_ "?")
    { return { $action: "select", table, filters } }

Insert_group = 
  token1:(_)
  table:Table_name
  token2:(_ "+" _)
  data:Insert_targets
    { return { $action: "insert", data } }

Insert_targets = Value
Insert_single_targets = Value

Update_group = 
  token1:(_)
  table:Table_name
  filters:Where_filters_precolons?
  token3:(_ "=" _)
  value:Insert_single_targets
    { return { $action: "update", table, filters, value } }

Delete_group = 
  token1:(_)
  table:Table_name
  token2:(_ "-" _)
  filters:Where_filters?
    { return { $action: "delete", table, filters } }
   
Where_filters_precolons =
  token1:(_ ":" _)
  filter:Where_filters
    { return filter }

Where_filters = Where_filter_by_id / Where_filter_by_name / Where_filter_by_rules / Where_filter_by_js_block / Injected_parameter

Where_filter_by_js_block = Js_block

Where_filter_by_id = Integer

Where_filter_by_name = String

Where_filter_by_rules = Where_expression

Where_expression = Where_rule

Where_rule = Where_rule_4
Where_rule_4 = Where_rule_3/Where_rule_2
Where_rule_3 = _
 src:Where_rule_2 _
 ops:Where_rule_3_continuation*
   { return { $type: "logical and/or operator", src, ops } }
Where_rule_3_continuation =
 op:Token_and_or_operator _
 dst:Where_rule_2
   { return { op, dst } }
Where_rule_2 = _ negated:"!"? _ rule:Where_rule_1 { return negated ? { $type: "negation", negated, rule } : rule }
Where_rule_1 = Where_rule_0 / Where_rule_pure
Where_rule_0 = _ "(" _ rule:Where_rule _ ")" { return { $type: "agroupation", rule } }

Token_and_or_operator = Token_and_operator / Token_or_operator
Token_and_operator = "and" / "&"
Token_or_operator = "or" / "|"

Where_rule_pure = _
  column:Column_name _
  operation:Column_operation
    { return [column, ...operation] }

Column_operation = Column_operation_1 / Column_operation_2

Column_operation_1 = Column_operator_1

Column_operation_2 = op:Column_operator_2 _ ob:Column_object { return [op, ob] }

Column_object = Json_value

Column_operator_1 = "is null" / "is not null"

Column_operator_2 = "<"
  / "<="
  / ">"
  / ">="
  / "="
  / "!="
  / "is in"
  / "is not in"

Subsentence_filter =
  token1:(_ ">" _)
  name:Function_name
  token2:(_ "(" _)
  parameters:List_of_function_parameters
  token3:(_ ")")
    { return { $type: "filter appendment", name, parameters } }

Subsentence_export =
  token1:(_ ">>" _)
  name:Function_parameter
    { return { $type: "export appendment", name } }

Subsentence_return =
  token1:(_ ">>>" _)
  name:Function_parameter
    { return { $type: "return appendment", name } }

Subsentence_multiply =
  token1:(_ "*" _)
  name:Function_parameter
    { return { $type: "multiply appendment", name } }

Function_name = Js_path

List_of_function_parameters =
  first:Function_parameter
  others:Function_parameter_precoma*
    { return [first].concat(others) }

Function_parameter = Value / Js_path
Function_parameter_precoma = token1:(_ "," _) param:Function_parameter { return param }

Integer = [0-9]+ { return parseInt(text()) }

Table_name = Js_noun

Column_name = Js_noun

Js_block = "{{" code:Js_block_content "}}" { return { $type: "js", code } }

Js_block_content = (!("}}") .)* { return text() }

Json_value = Json_value_pure / Js_block / Update_group / Select_group / Insert_group / Delete_group / Injected_parameter

Json_value_pure =
  tp:Type_def? _ vl:Value_untyped { return tp ? { ...tp, $value: vl } : vl; }

// Define una `Type_def` que acepta URLs completas
Type_def = Type_def_by_request / Type_def_by_js_property

Js_noun = [A-Za-z\$_] [A-Za-z0-9\$_]* { return text() }

Js_noun_predotted =
  "." noun:Js_noun
    { return noun }

Js_noun_accessed = Js_noun_predotted / Js_noun_accessed_by_squarebrackets

Js_noun_accessed_by_squarebrackets =
  "[" noun:String "]"
    { return noun }

Js_path = 
  first:Js_noun
  others:Js_noun_accessed*
    { return { $type: "js-path", path: [first].concat(others || []) } }

Type_def_by_js_property
  = "@" jspath:Js_path
    {
      return {
        $protocol: jspath,
      };
    }

Type_def_by_request
  = "@" protocol:Type_protocol "//" "/"? host:Host path:Path? query:Query_string? fragment:Fragment? {
      return {
        $protocol: protocol,
        $host: host,
        $path: path || "/",
        $query: query || null,
        $fragment: fragment || null
      };
    }

Type_protocol
  = protocol:([A-Za-z][A-Za-z0-9+\-.]* ":") {
      return text().slice(0, -1); // Remueve el ":" del final
    }

Host
  = host:([A-Za-z0-9\-._~%]+) {
      return host.join("");
    }

Path
  = path:("/" [A-Za-z0-9\-._~%!$&'()*+,;=:@/]*) {
      return text().substr(1);
    }

Query_string
  = "?" params:Query_param_list {
      return params;
    }

Query_param_list
  = head:Query_param tail:("&" Query_param)* {
      return [head, ...tail.map(item => item[1])];
    }

Query_param
  = key:[A-Za-z0-9\-._~%]+ "=" value:[A-Za-z0-9\-._~%]+ {
      return { key: key.join(""), value: value.join("") };
    }

Fragment
  = "#" id:[A-Za-z0-9\-._~%!$&'()*+,;=:@/]+ {
      return id.join("");
    }

Value_untyped
  = Object
  / Array
  / String
  / Number
  / Boolean
  / Null

Object
  = "{" _ members:MemberList? _ "}" {
      return members !== null ? members : {};
    }

MemberList
  = head:Member tail:(_ "," _ Member)* {
      const result = { [head.key]: head.value };
      tail.forEach((item) => {
        const subitem = item[3];
        const { key, value } = subitem;
        result[key] = value;
      });
      return result;
    }

Member_key = String / Js_noun

Member
  = key:Member_key _ ":" _ value:Value {
      return { key, value };
    }

Array
  = "[" _ elements:ElementList? _ "]" {
      return elements !== null ? elements : [];
    }

ElementList
  = head:Value tail:(_ "," _ Value)* {
      return [head, ...tail.map(e => e[3])];
    }

String
  = '"' chars:DoubleQuotedString '"' {
      return chars;
    }

DoubleQuotedString
  = chars:('\\"' / ((!'"') .))* { return text(); }

Number
  = value:$("-"? [0-9]+ ("." [0-9]+)? ([eE] [-+]? [0-9]+)?) {
      return parseFloat(value);
    }

Boolean
  = "true" { return true; }
  / "false" { return false; }

Null
  = "null" { return null; }

_ "whitespace"
  = [ \t\n\r]*
