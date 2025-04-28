# only works with the Java extension of yacc: 
# byacc/j from http://troi.lincom-asg.com/~rjamison/byacc/

JFLEX  = java -jar jflex.jar
BYACCJ = ./yacc.linux -tv -J
#BYACCJ = byaccj -tv -J
JAVAC  = javac

# targets:

all: Parser.class

run: Parser.class
	java Parser

build: clean Parser.class

clean:
	rm -f *~ *.class *.o *.s Yylex.java Parser.java y.output

Parser.class: Yylex.java Parser.java
	$(JAVAC) Parser.java

Yylex.java: lexico.flex
	$(JFLEX) lexico.flex

Parser.java: exerc.y Yylex.java
	$(BYACCJ) exerc.y
