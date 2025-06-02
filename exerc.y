%{
  import java.io.*;
  import java.util.*;

  enum Tipo { INT, DOUBLE, BOOLEAN, VOID }

  class FuncaoInfo {
    Tipo retorno;
    List<Tipo> parametros;

    FuncaoInfo(Tipo r, List<Tipo> p) {
      this.retorno = r;
      this.parametros = p;
    }
  }

  Map<String, Tipo> variaveisGlobais = new HashMap<>();
  Map<String, FuncaoInfo> funcoes = new LinkedHashMap<>();

  Deque<Map<String, Tipo>> pilhaEscopos = new ArrayDeque<>();

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
    for (Map<String, Tipo> escopo : pilhaEscopos)
      if (escopo.containsKey(nome)) return true;
    return variaveisGlobais.containsKey(nome);
  }

  Tipo tipoVariavel(String nome) {
    for (Map<String, Tipo> escopo : pilhaEscopos)
      if (escopo.containsKey(nome)) return escopo.get(nome);
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

  boolean tiposCompativeis(Tipo a, Tipo b) {
    return a == b || (a == Tipo.INT && b == Tipo.DOUBLE) || (a == Tipo.DOUBLE && b == Tipo.INT);
  }

  void checaTipoAtribuicao(Tipo destino, Tipo origem) {
    if (!tiposCompativeis(destino, origem))
      yyerror("Tipo incompatível na atribuição: esperado " + destino + ", encontrado " + origem);
  }

  Tipo exprTipo;

%}

%token IF DO TO THEN ELSE ENDIF NUM IDENT RETURN VOID WHILE
%token INT DOUBLE BOOLEAN
%token AND

%left '+' '-'
%left '*' '/'
%left '>'
%right '='

%union {
  Integer ival;
  String sval;
  Tipo tval;
  List<Tipo> ltipo;
  List<String> lstring;
}

%type <tval> Tipo TipoOuVoid
%type <ltipo> ListaParametros
%type <tval> E Expr Cmd
%type <tval> ListaArgs
%type <ltipo> ListaArgsOuVazio
%type <lstring> LId

%%

Prog : Decl ListaFuncoes
    ;

Decl : Tipo LId ';' Decl
     {
       for(String var : $2)
         insereVariavel(var, $1);
     }
     | /* vazio */
     ;

Tipo : INT { $$ = Tipo.INT; }
     | DOUBLE { $$ = Tipo.DOUBLE; }
     | BOOLEAN { $$ = Tipo.BOOLEAN; }
     ;

LId : LId ',' IDENT { $1.add($3); $$ = $1; }
    | IDENT { List<String> vars = new ArrayList<>(); vars.add($1); $$ = vars; }
    ;

ListaFuncoes : ListaFuncoes Funcao
             | Funcao
             ;

Funcao : TipoOuVoid IDENT '(' ListaParametrosOuVazio ')' Bloco
      {
        if (funcoes.containsKey($2))
          yyerror("Função "+$2+" já declarada");

        funcoes.put($2, new FuncaoInfo($1, $4));

        if ($2.equals("main") && !isUltimaFuncao($2)) {
          yyerror("Função main deve ser a última declarada");
        }

        if ($1 != Tipo.VOID && !viuReturn) {
          yyerror("Função "+$2+" deve ter um comando return");
        }

        viuReturn = false;
        tipoFuncaoAtual = null;
        funcaoAtual = null;
      }
      ;

TipoOuVoid : VOID { $$ = Tipo.VOID; }
           | Tipo { $$ = $1; tipoFuncaoAtual = $1; }
           ;

ListaParametrosOuVazio : ListaParametros { $$ = $1; }
                      | /* vazio */ { abreEscopo(); $$ = new ArrayList<>(); }
                      ;

ListaParametros : Tipo IDENT {
                    List<Tipo> params = new ArrayList<>();
                    params.add($1);
                    abreEscopo();
                    insereVariavel($2, $1);
                    $$ = params;
                }
                | Tipo IDENT ',' ListaParametros {
                    $4.add(0, $1);
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
        if (tipoFuncaoAtual == Tipo.VOID)
          yyerror("Função void não deve retornar valor");
        else if (!tiposCompativeis(tipoFuncaoAtual, $2))
          yyerror("Tipo retornado incompatível: esperado "+tipoFuncaoAtual+" encontrado "+$2);
        viuReturn = true;
      }
    | RETURN ';'
      {
        if (tipoFuncaoAtual != Tipo.VOID)
          yyerror("Função não-void deve retornar um valor");
        viuReturn = true;
      }
    | E ';'
    ;

E : E '=' E { checaTipoAtribuicao($1, $3); $$ = $1; }
  | E '+' E { if (!tiposCompativeis($1, $3)) yyerror("'+' requer int ou double"); $$ = ($1 == Tipo.DOUBLE || $3 == Tipo.DOUBLE) ? Tipo.DOUBLE : Tipo.INT; }
  | E '*' E { if (!tiposCompativeis($1, $3)) yyerror("'*' requer int ou double"); $$ = ($1 == Tipo.DOUBLE || $3 == Tipo.DOUBLE) ? Tipo.DOUBLE : Tipo.INT; }
  | E '/' E { if (!tiposCompativeis($1, $3)) yyerror("'/' requer int ou double"); $$ = ($1 == Tipo.DOUBLE || $3 == Tipo.DOUBLE) ? Tipo.DOUBLE : Tipo.INT; }
  | E '>' E { if (!tiposCompativeis($1, $3)) yyerror("'>' requer int ou double"); $$ = Tipo.BOOLEAN; }
  | E AND E { if ($1 != Tipo.BOOLEAN || $3 != Tipo.BOOLEAN) yyerror("AND requer boolean"); $$ = Tipo.BOOLEAN; }
  | NUM { $$ = Tipo.INT; }
  | IDENT {
      if (!existeVariavel($1)) yyerror("Variável "+$1+" não declarada");
      $$ = tipoVariavel($1);
    }
  | IDENT '(' ListaArgsOuVazio ')' {
      if (!funcoes.containsKey($1))
        yyerror("Função "+$1+" não declarada");
      FuncaoInfo fi = funcoes.get($1);
      if (fi.parametros.size() != $3.size())
        yyerror("Número de argumentos errado para função "+$1);
      else {
        for (int i = 0; i < $3.size(); i++) {
          if (!tiposCompativeis(fi.parametros.get(i), $3.get(i)))
            yyerror("Tipo do argumento "+(i+1)+" errado para função "+$1);
        }
      }
      $$ = fi.retorno;
    }
  | '(' E ')' { $$ = $2; }
  ;

ListaArgsOuVazio : ListaArgs { $$ = $1; }
                 | /* vazio */ { $$ = new ArrayList<>(); }
                 ;

ListaArgs : E { List<Tipo> args = new ArrayList<>(); args.add($1); $$ = args; }
          | E ',' ListaArgs { $3.add(0, $1); $$ = $3; }
          ;

%%

// Verifica se main é a última função declarada
private boolean isUltimaFuncao(String nome) {
  boolean depoisDeMain = false;
  boolean achouMain = false;
  for (String fname : funcoes.keySet()) {
    if (fname.equals("main")) achouMain = true;
    else if (achouMain) depoisDeMain = true;
  }
  return !depoisDeMain;
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
  System.err.println ("Erro: " + error);
}

public Parser(Reader r) {
  lexer = new Yylex(r, this);
}

public static void main(String args[]) throws IOException {
  Reader reader;
  if (args.length > 0)
    reader = new FileReader(args[0]);
  else
    reader = new InputStreamReader(System.in);
    
  Parser parser = new Parser(reader);
  parser.yyparse();
}
