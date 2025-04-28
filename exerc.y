%{
  import java.io.*;
%}
   

%token IF, DO, TO, THEN, ELSE, BY, endif, num, ident

%left '+' '-'
%left '*' '/'
%left '>'
%left 'AND'

%%
 
Prog : Decl  ListaFuncoes      
     ;          

Decl : Tipo LId ';'  Decl
     |     //produção vazia 
     :                       

Tipo : int 
     | double 
     | boolean     
     ;         

LId : LId ',' IDENT
    | IDENT      
    ; 

ListaFuncoes : ListaFuncoes Funcao
             | //produçãoo vazia 
             ;


Funcao : TipoOuVoid ident '('ListaParametrosOuVazio ')' Bloco
       ;

TipoOuVoid : VOID
           | Tipo
           ;

ListaParametrosOuVazio : ListaParametros
                       | //produçãoo vazia 
                       ;

ListaParametros : Tipo IDENT 
                | Tipo IDENT , ListaParametros    
                ;  

Bloco -->  '{' LCmd '}'            

LCmd : Cmd LCmdo             
     |     //produçãoo vazia
     ;

Cmd : Bloco
    | if ( E ) Cmd
    | if ( E ) Cmd else Cmd
    | while ( E ) Cmd
    |  E  ;           
    ;

E : E = E        
  | E + E
  | E * E   
  | E / E   
  | E > E   
  | E AND E       
  | NUM
  | IDENT 
  | ( E )
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






