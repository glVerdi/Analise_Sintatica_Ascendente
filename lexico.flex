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

// Palavras-chave
"if"       { return Parser.IF; }
"else"     { return Parser.ELSE; }
"while"    { return Parser.WHILE; }
"int"      { return Parser.INT; }
"double"   { return Parser.DOUBLE; }
"boolean"  { return Parser.BOOLEAN; }
"void"     { return Parser.VOID; }
"AND"      { return Parser.AND; }

// Literais e identificadores
[0-9]+     { return Parser.NUM; }
[a-zA-Z_][a-zA-Z0-9_]*  { return Parser.IDENT; }

// Operadores e símbolos
"="        { return Parser.EQ; }     // você pode usar EQ ou diretamente '=' se preferir
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

// Ignorar espaços e quebras de linha
[ \t]+     { }
{NL}+      { }

// Tratamento de erro
.          { System.err.println("Erro: caractere inesperado '" + yytext() + "' na linha " + (yyline + 1)); return YYEOF; }
