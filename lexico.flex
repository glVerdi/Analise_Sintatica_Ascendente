%%
%byaccj

%{
  private Parser yyparser;

  public Yylex(java.io.Reader r, Parser yyparser) {
    this(r);
    this.yyparser = yyparser;
  }
%}

NL = \n | \r | \r\n

%%

"if"       { return Parser.IF; }
"else"     { return Parser.ELSE; }
"while"    { return Parser.WHILE; }
"int"      { return Parser.INT; }
"double"   { return Parser.DOUBLE; }
"boolean"  { return Parser.BOOLEAN; }
"void"     { return Parser.VOID; }
"AND"      { return Parser.AND; }

[0-9]+     { return Parser.NUM; }
[a-zA-Z_][a-zA-Z0-9_]*  { return Parser.IDENT; }

"="        { return '='; }     
"+"        { return '+'; }
"-"        { return '-'; }
"*"        { return '*'; }
"/"        { return '/'; }
">"        { return Parser.GT; }

","        { return ','; }
";"        { return ';'; }
"("        { return '('; }
")"        { return ')'; }
"{"        { return '{'; }
"}"        { return '}'; }

[ \t]+     { }
{NL}+      { }

.          { System.err.println("Erro: caractere inesperado '" + yytext() + "' na linha " + (yyline + 1)); return YYEOF; }
