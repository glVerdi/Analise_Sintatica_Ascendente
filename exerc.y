%{
  import java.io.*;
  import java.util.*;

  // Representação dos tipos
  enum Tipo { INT, DOUBLE, BOOLEAN, VOID }

  class FuncaoInfo {
    Tipo retorno;
    List<Tipo> parametros;

    FuncaoInfo(Tipo r, List<Tipo> p) {
      this.retorno = r;
      this.parametros = p;
    }
  }

  // Tabelas de símbolos
  Map<String, Tipo> variaveisGlobais = new HashMap<>();
  Map<String, FuncaoInfo> funcoes = new HashMap<>();

  // Para controle de escopo local
  Deque<Map<String, Tipo>> pilhaEscopos = new ArrayDeque<>();

  // Função atual para verificar return
  String funcaoAtual = null;
  Tipo tipoFuncaoAtual = null;
  boolean viuReturn = false;

  void abreEscopo() {
    pilhaEscopos.push(new HashMap<>());
  }

  void fechaEscopo() {
    pilhaEscopos.pop();
  }

  boolean existeVariavel(String nome) {
    for (Map<String, Tipo> escopo : pilhaEscopos) {
      if (escopo.containsKey(nome)) return true;
    }
    return variaveisGlobais.containsKey(nome);
  }

  Tipo tipoVariavel(String nome) {
    for (Map<String, Tipo> escopo : pilhaEscopos) {
      if (escopo.containsKey(nome)) return escopo.get(nome);
    }
    return variaveisGlobais.get(nome);
  }

  void insereVariavel(String nome, Tipo tipo) {
    if (pilhaEscopos.isEmpty()) {
      if (variaveisGlobais.containsKey(nome))
        yyerror("Variável global "+nome+" já declarada");
      variaveisGlobais.put(nome, tipo);
    } else {
      Map<String, Tipo> atual = pilhaEscopos.peek();
      if (atual.containsKey(nome))
        yyerror("Variável local "+nome+" já declarada");
      atual.put(nome, tipo);
    }
  }

  // Verifica compatibilidade de tipos simplificada
  boolean tiposCompativeis(Tipo a, Tipo b) {
    if (a == b) return true;
    if ((a == Tipo.INT && b == Tipo.DOUBLE) || (a == Tipo.DOUBLE && b == Tipo.INT)) return true; 
    return false;
  }

  void checaTipoAtribuicao(Tipo destino, Tipo origem) {
    if (!tiposCompativeis(destino, origem)) {
      yyerror("Tipo incompatível na atribuição: esperado " + destino + ", encontrado " + origem);
    }
  }

  // Variável para armazenar o tipo da expressão no momento da redução
  Tipo exprTipo;

%}

%token IF DO TO THEN ELSE ENDIF NUM IDENT
%token RETURN VOID

%left '+' '-'
%left '*' '/'
%left '>'
%left AND

%union {
  Integer ival;
  String sval;
  Tipo tval;
  List<Tipo> ltipo;
  List<String> lstring;
}

%type <tval> Tipo TipoOuVoid
%type <ltipo> ListaParametros
%type <tval> E
%type <tval> Expr
%type <tval> Cmd

%%

Prog : Decl ListaFuncoes
    ;

Decl : Tipo LId ';' Decl
     {
       // Para cada variável declarada, inserir no escopo global
       for(String var : $2) {
         insereVariavel(var, $1);
       }
     }
     | /* vazio */
     ;

Tipo : INT { $$ = Tipo.INT; }
     | DOUBLE { $$ = Tipo.DOUBLE; }
     | BOOLEAN { $$ = Tipo.BOOLEAN; }
     ;

LId : LId ',' IDENT { 
        $1.add($3); 
        $$ = $1; 
     }
    | IDENT { 
        List<String> vars = new ArrayList<>();
        vars.add($1);
        $$ = vars;
      }
    ;

ListaFuncoes : ListaFuncoes Funcao
             | Funcao
             ;

Funcao : TipoOuVoid IDENT '(' ListaParametrosOuVazio ')' Bloco
      {
        // Inserir função na tabela
        if (funcoes.containsKey($2))
          yyerror("Função "+$2+" já declarada");
        funcoes.put($2, new FuncaoInfo($1, $4));

        // Função main deve ser última
        if ($2.equals("main") && !isUltimaFuncao()) {
          yyerror("Função main deve ser a última declarada");
        }
      }
      ;

TipoOuVoid : VOID { $$ = Tipo.VOID; }
           | Tipo { $$ = $1; }
           ;

ListaParametrosOuVazio : ListaParametros { $$ = $1; }
                      | /* vazio */ { $$ = new ArrayList<>(); }
                      ;

ListaParametros : Tipo IDENT {
                    List<Tipo> params = new ArrayList<>();
                    params.add($1);
                    // abrir escopo e inserir parâmetros localmente no escopo da função
                    abreEscopo();
                    insereVariavel($2, $1);
                    $$ = params;
                }
                | Tipo IDENT ',' ListaParametros {
                    $4.add(0, $2);
                    insereVariavel($2, $1);
                    $$ = $4;
                }
                ;

Bloco : '{' LCmd '}'
      {
        fechaEscopo();
      }
      ;

LCmd : Cmd LCmd
     | /* vazio */
     ;

Cmd : Bloco
    | IF '(' E ')' Cmd
    | IF '(' E ')' Cmd ELSE Cmd
    | WHILE '(' E ')' Cmd
    | RETURN E ';'
      {
        if (tipoFuncaoAtual == Tipo.VOID) {
          yyerror("Função void não deve retornar valor");
        } else {
          if (!tiposCompativeis(tipoFuncaoAtual, $2))
            yyerror("Tipo retornado incompatível: esperado "+tipoFuncaoAtual+" encontrado "+$2);
        }
        viuReturn = true;
      }
    | RETURN ';'
      {
        if (tipoFuncaoAtual != Tipo.VOID) {
          yyerror("Função não-void deve retornar um valor");
        }
        viuReturn = true;
      }
    | E ';'
    ;

E : E '=' E
    {
      Tipo tipoEsq = $1;
      Tipo tipoDir = $3;
      checaTipoAtribuicao(tipoEsq, tipoDir);
      $$ = tipoEsq;
    }
  | E '+' E
    {
      if (($1 != Tipo.INT && $1 != Tipo.DOUBLE) || ($3 != Tipo.INT && $3 != Tipo.DOUBLE))
        yyerror("Operação '+' só aceita int ou double");
      if ($1 == Tipo.DOUBLE || $3 == Tipo.DOUBLE) $$ = Tipo.DOUBLE; else $$ = Tipo.INT;
    }
  | E '*' E
    {
      if (($1 != Tipo.INT && $1 != Tipo.DOUBLE) || ($3 != Tipo.INT && $3 != Tipo.DOUBLE))
        yyerror("Operação '*' só aceita int ou double");
      if ($1 == Tipo.DOUBLE || $3 == Tipo.DOUBLE) $$ = Tipo.DOUBLE; else $$ = Tipo.INT;
    }
  | E '/' E
    {
      if (($1 != Tipo.INT && $1 != Tipo.DOUBLE) || ($3 != Tipo.INT && $3 != Tipo.DOUBLE))
        yyerror("Operação '/' só aceita int ou double");
      if ($1 == Tipo.DOUBLE || $3 == Tipo.DOUBLE) $$ = Tipo.DOUBLE; else $$ = Tipo.INT;
    }
  | E '>' E
    {
      if (($1 != Tipo.INT && $1 != Tipo.DOUBLE) || ($3 != Tipo.INT && $3 != Tipo.DOUBLE))
        yyerror("Operação '>' só aceita int ou double");
      $$ = Tipo.BOOLEAN;
    }
  | E AND E
    {
      if ($1 != Tipo.BOOLEAN || $3 != Tipo.BOOLEAN)
        yyerror("Operação AND só aceita boolean");
      $$ = Tipo.BOOLEAN;
    }
  | NUM
    {
      $$ = Tipo.INT; // vamos assumir que NUM é int (pode adaptar para double)
    }
  | IDENT
    {
      if (!existeVariavel($1))
        yyerror("Variável "+$1+" não declarada");
      $$ = tipoVariavel($1);
    }
  | IDENT '(' ListaArgsOuVazio ')'
    {
      if (!funcoes.containsKey($1))
        yyerror("Função "+$1+" não declarada");
      FuncaoInfo fi = funcoes.get($1);
      List<Tipo> args = $3;
      if (fi.parametros.size() != args.size())
        yyerror("Número de argumentos errado para função "+$1);
      else {
        for (int i = 0; i < args.size(); i++) {
          if (!tiposCompativeis(fi.parametros.get(i), args.get(i))) {
            yyerror("Tipo do argumento "+(i+1)+" errado para função "+$1);
          }
        }
      }
      $$ = fi.retorno;
    }
  | '(' E ')'
    {
      $$ = $2;
    }
  ;

ListaArgsOuVazio : ListaArgs { $$ = $1; }
                 | /* vazio */ { $$ = new ArrayList<>(); }
                 ;

ListaArgs : E
          {
            List<Tipo> args = new ArrayList<>();
            args.add($1);
            $$ = args;
          }
          | E ',' ListaArgs
          {
            $3.add(0, $1);
            $$ = $3;
          }
          ;

%%

// Função para verificar se main é última função
private boolean isUltimaFuncao() {
  // Implementar de acordo com a estrutura real, aqui assume true por simplicidade
  // Ou controlar um contador de funções e ver se ainda vem mais depois da main
  return true; // simplificação
}

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
  else {
    System.out.print("> ");
    interactive = true;
    yyparser = new Parser(new InputStreamReader(System.in));
  }

  yyparser.yyparse();

  System.out.println();
  System.out.println("done!");
}

