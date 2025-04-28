%%

%byaccj


%{
  private Parser yyparser;

  public Yylex(java.io.Reader r, Parser yyparser) {
    this(r);
    this.yyparser = yyparser;
  }
%}

NL  = \n | \r | \r\n

%%

"$TRACE_ON"  { yyparser.setDebug(true);  }
"$TRACE_OFF" { yyparser.setDebug(false); }

if { return Parser.IF;}
do { return Parser.DO; }
to { return Parser.TO; }
then { return Parser.THEN;}
else { return Parser.ELSE;}
by { return Parser.BY;} 
endif { return Parser.endif;}

[0-9]+ { return Parser.num;}
[a-zA-Z][a-zA-Z0-9]* { return Parser.ident;}

"{" |
"}" |
"=" |
"(" |
")" |
";" |
"*" |
"/" |
"+" |
"-"     { return (int) yycharat(0); }

[ \t]+ { }
{NL}+  { } 

.    { System.err.println("Error: unexpected character '"+yytext()+"' na linha "+yyline); return YYEOF; }






