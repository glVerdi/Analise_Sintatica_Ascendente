%{
  import java.io.*;
%}
   

%token IF, DO, TO, THEN, ELSE, BY, endif, num, ident

%left '+' '-'
%left '*' '/'

%%
 
Prog :  Bloco
    ;

Bloco : '{' LCmd '}'
      ;

LCmd : LCmd  C
     |       // vazio
     ;

C : ident '=' E ';'
  | IF '(' E ')' THEN C endif
  | IF '(' E ')' THEN C ELSE C endif  
  ;


E : E '+' E
  | E '-' E
  | E '*' E 
  | E '/' E
  | num
  | ident
;


%%

  private Yylex lexer;


  private int yylex () {
    int yyl_return = -1;
    try {
      yylval = new ParserVal(0);
      yyl_return = lexer.yylex();
    }
    catch (IOException e) {
      System.err.println("IO error :"+e.getMessage());
    }
    return yyl_return;
  }


  public void yyerror (String error) {
    System.err.println ("Error: " + error);
  }


  public Parser(Reader r) {
    lexer = new Yylex(r, this);
  }


  static boolean interactive;

  public void setDebug(boolean debug) {
    yydebug = debug;
  }


  public static void main(String args[]) throws IOException {
    System.out.println("");

    Parser yyparser;
    if ( args.length > 0 ) {
      // parse a file
      yyparser = new Parser(new FileReader(args[0]));
    }
    else {System.out.print("> ");
      interactive = true;
	    yyparser = new Parser(new InputStreamReader(System.in));
    }

    yyparser.yyparse();
    
  //  if (interactive) {
      System.out.println();
      System.out.println("done!");
  //  }
  }






