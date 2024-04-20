
%{
#include<bits/stdc++.h>
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "2005117_SymbolTable.h"

#define total_buckets 11

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int lineCount;
extern int errorCount;
int ssErrorCount = 0;

ofstream logWrite;
ofstream errorWrite;
ofstream ptWrite; 

SymbolTable *Table = new SymbolTable(total_buckets);
SymbolInfo scopeParam;




void yyerror(string s)
{
	//errorWrite<<"Line# "<<lineCount<<": "<<s<<endl;
}


void printParseTree(SymbolInfo *symbol, int depth)
{

	
	for(int i =0;i<depth;i++)
	{
		ptWrite<<" ";
	}
	
    if(symbol->getLeafStatus())
	{
		
		ptWrite<<symbol->getSymbolType()<<" : "<<symbol->getSymbolName()<<"\t<Line: "<<symbol->getStartLine()<<">"<<endl;
		return;
		
	}
	
	else
	{
		
		ptWrite<<symbol->getSymbolType()<<" : "<<symbol->getSymbolName()<<"\t<Line: "<<symbol->getStartLine()<<"-"<<symbol->getEndLine()<<">"<<endl;
		for( auto child : symbol->getChildren())
		{
			printParseTree(child,depth+1);
			
		}
		
	}
	
}


%}
%union {
	SymbolInfo *symbolInfo;
}

%token<symbolInfo> IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE CONST_INT CONST_FLOAT CONST_CHAR ID NOT LOGICOP RELOP ADDOP MULOP INCOP DECOP ASSIGNOP LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON BITOP SINGLE_LINE_STRING MULTI_LINE_STRING LOWER_THAN_ELSE PRINTLN
%type<symbolInfo> start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments LCURL_

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		
		logWrite<<"start : program"<<endl;
		$$ = new SymbolInfo("program","start");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		$$->addChild($1);

		printParseTree($$,0);
		
		logWrite<<"Total Lines: "<<lineCount<<endl;
		logWrite<<"Total Errors: "<<ssErrorCount + errorCount<<endl;
		$$ = NULL;
	}
	;

program : program unit 
	{
		logWrite<<"program : program unit"<<endl;
		$$ = new SymbolInfo("program unit","program");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
		$$->addChild($1);
		$$->addChild($2);
	}
	| unit
	{
		logWrite<<"program : unit"<<endl;
		$$ = new SymbolInfo("unit","program");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		$$->addChild($1);
	}
	;

unit : var_declaration
	{
		logWrite<<"unit : var_declaration"<<endl;
		$$ = new SymbolInfo("var_declaration","unit");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		$$->addChild($1);
	}
     | func_declaration
	 {
		logWrite<<"unit : func_declaration"<<endl;
		$$ = new SymbolInfo("func_declaration","unit");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		$$->addChild($1);
	 }
     | func_definition
	 {
		logWrite<<"unit : func_definition"<<endl;
		$$ = new SymbolInfo("func_definition","unit");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		$$->addChild($1);
	 }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		logWrite<<"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON"<<endl;
		$$ = new SymbolInfo("type_specifier ID LPAREN parameter_list RPAREN SEMICOLON","func_declaration");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($6->getEndLine());
		$$->addChild($1);
		$$->addChild($2);
		$$->addChild($3);
		$$->addChild($4);
		$$->addChild($5);
		$$->addChild($6);

		SymbolInfo *symbol = new SymbolInfo($2->getSymbolName(),"FUNCTION");
		symbol->setTypeSpecifier($1->getTypeSpecifier());
		vector<SymbolInfo*> ParamList = $4->getParameterList();
		for(int i =0;i< ParamList.size();i++)
		{
			for(int j = i+1;j<ParamList.size();j++)
			{
				if(ParamList[i]->getSymbolName()==ParamList[j]->getSymbolName())
				{
					ssErrorCount++;
					errorWrite<<"Line# "<<$$->getStartLine()<<": Redefinition of parameter \'"<<ParamList[i]->getSymbolName()<<"\'"<<endl;
				}
			}
			symbol->addToParameterList(ParamList[i]);
		}
		symbol->setFunctionStatus(true);
		bool success = Table->insertSymbol(symbol);
		if(!success)
		{
			//error
			ssErrorCount++;
			SymbolInfo *checker = Table->lookupSymbol(symbol->getSymbolName());
			if(checker->getFunctionStatus()==false)
			{
				errorWrite<<"Line# "<<$$->getStartLine()<<": \'"<<symbol->getSymbolName()<<"\' redeclared as different kind of symbol"<<endl;
			}
			else
			{
				errorWrite<<"Line# "<<$$->getStartLine()<<": Multiple declarations of function \'"<<symbol->getSymbolName()<<"\'"<<endl;
			}
		}
		scopeParam.clearParameterList();
		
	}
		| type_specifier ID LPAREN RPAREN SEMICOLON
	{
			logWrite<<"func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON"<<endl;
			$$ = new SymbolInfo("type_specifier ID LPAREN RPAREN SEMICOLON", "func_declaration");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5);
		
		SymbolInfo *symbol = new SymbolInfo($2->getSymbolName(),"FUNCTION");
		symbol->setTypeSpecifier($1->getTypeSpecifier());
		symbol->setFunctionStatus(true);
		bool success = Table->insertSymbol(symbol);
		if(!success)
		{
			//error
			ssErrorCount++;
			SymbolInfo *checker = Table->lookupSymbol(symbol->getSymbolName());
			if(checker->getFunctionStatus()==false)
			{
				errorWrite<<"Line# "<<$$->getStartLine()<<": \'"<<symbol->getSymbolName()<<"\' redeclared as different kind of symbol"<<endl;
			}
			else
			{
				errorWrite<<"Line# "<<$$->getStartLine()<<": Multiple declarations of function \'"<<symbol->getSymbolName()<<"\'"<<endl;
			}
		}
		scopeParam.clearParameterList();
		}	
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
    {
		    logWrite<<"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<endl;
		    $$ = new SymbolInfo("type_specifier ID LPAREN parameter_list RPAREN compound_statement", "func_definition");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($6->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5);
			$$->addChild($6); 

		SymbolInfo *symbol = new SymbolInfo($2->getSymbolName(),"FUNCTION");
		symbol->setTypeSpecifier($1->getTypeSpecifier());
		vector<SymbolInfo*> ParamList = $4->getParameterList();
		for(int i =0;i< ParamList.size();i++)
		{
			for(int j = i+1;j<ParamList.size();j++)
			{
				if(ParamList[i]->getSymbolName()==ParamList[j]->getSymbolName())
				{
					ssErrorCount++;
					errorWrite<<"Line# "<<$$->getStartLine()<<": Redefinition of parameter \'"<<ParamList[i]->getSymbolName()<<"\'"<<endl;
				}
			}
			symbol->addToParameterList(ParamList[i]);
		}
		symbol->setFunctionStatus(true);
		bool success = Table->insertSymbol(symbol);
		if(!success)
		{
		
			SymbolInfo *checker = Table->lookupSymbol(symbol->getSymbolName());
			if(checker->getFunctionStatus()==false)
			{
				errorWrite<<"Line# "<<$$->getStartLine()<<": \'"<<symbol->getSymbolName()<<"\' redeclared as different kind of symbol"<<endl;
				ssErrorCount++;
			}
			else
			{
				if(checker->getTypeSpecifier()!=symbol->getTypeSpecifier() || checker->getParameterList().size()!=symbol->getParameterList().size())
				{
					errorWrite<<"Line# "<<$$->getStartLine()<<": Conflicting types for \'"<<symbol->getSymbolName()<<"\'"<<endl;
					ssErrorCount++;
				}
				else if(checker->getParameterList().size()==symbol->getParameterList().size())
				{
					for(int i = 0;i<checker->getParameterList().size();i++)
					{
						if(checker->getParameterList()[i]->getTypeSpecifier()!=symbol->getParameterList()[i]->getTypeSpecifier())
						{
							ssErrorCount++;
							errorWrite<<"Line# "<<$$->getStartLine()<<": Type mismatch for parameter"<< i+1<<" of \'"<<symbol->getSymbolName()<<"\'"<<endl;
						}
					}
				}
			}
		}
	}
		| type_specifier ID LPAREN RPAREN compound_statement
	{
			logWrite<<"func_definition : type_specifier ID LPAREN  RPAREN compound_statement"<<endl;
		    $$ = new SymbolInfo("type_specifier ID LPAREN RPAREN compound_statement", "func_definition");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5); 

		SymbolInfo *symbol = new SymbolInfo($2->getSymbolName(),"FUNCTION");
		symbol->setTypeSpecifier($1->getTypeSpecifier());
		symbol->setFunctionStatus(true);
		bool success = Table->insertSymbol(symbol);
		if(!success)
		{
		
			SymbolInfo *checker = Table->lookupSymbol(symbol->getSymbolName());
			if(checker->getFunctionStatus()==false)
			{
				errorWrite<<"Line# "<<$$->getStartLine()<<": \'"<<symbol->getSymbolName()<<"\' redeclared as different kind of symbol"<<endl;
				ssErrorCount++;
			}
			else
			{
				if(checker->getTypeSpecifier()!=symbol->getTypeSpecifier() || checker->getParameterList().size()!=symbol->getParameterList().size())
				{
					errorWrite<<"Line# "<<$$->getStartLine()<<": Conflicting types for \'"<<symbol->getSymbolName()<<"\'"<<endl;
					ssErrorCount++;
				}
				else if(checker->getParameterList().size()==symbol->getParameterList().size())
				{
					vector<SymbolInfo*> checkerParamList = checker->getParameterList();
					vector<SymbolInfo*> symbolParamList = symbol->getParameterList();
					for(int i = 0;i<checker->getParameterList().size();i++)
					{
						if(checkerParamList[i]->getTypeSpecifier() != symbolParamList[i]->getTypeSpecifier())
						{
							errorWrite<<"Line# "<<$$->getStartLine()<<": Type mismatch for parameter"<< i+1<<" of \'"<<symbol->getSymbolName()<<"\'"<<endl;
							ssErrorCount++;
						}
					}
				}
			}
		}
	}

	| type_specifier ID LPAREN error RPAREN compound_statement
	   {
		 ssErrorCount++;
		 errorWrite<<"Line# "<<$1->getStartLine()<<": Syntax error at parameter list of function definition"<<endl;
		 }
 		;				


parameter_list : parameter_list COMMA type_specifier ID
    {
			logWrite<<"parameter_list  : parameter_list COMMA type_specifier ID"<<endl;
		    $$ = new SymbolInfo("parameter_list COMMA type_specifier ID", "parameter_list");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($4->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);

			if($3->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line #"<<lineCount<<": Function parameter can not be void"<<endl;
			}
			else
			{
				for(auto param : $1->getParameterList())
				{
					$$->addToParameterList(param);
				}

				$4->setTypeSpecifier($3->getTypeSpecifier());
				$$->addToParameterList($4);
				scopeParam.addToParameterList($4);
			}

	}
		| parameter_list COMMA type_specifier
	{
			logWrite<<"parameter_list  : parameter_list COMMA type_specifier"<<endl;
		    $$ = new SymbolInfo("parameter_list COMMA type_specifier", "parameter_list");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);

			if($3->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line #"<<lineCount<<": Function parameter can not be void"<<endl;
			}
			else
			{
				for(auto param : $1->getParameterList())
				{
					$$->addToParameterList(param);
				}
				SymbolInfo* newParam = new SymbolInfo("","ID");
				newParam->setTypeSpecifier($3->getTypeSpecifier());
				$$->addToParameterList(newParam);
				scopeParam.addToParameterList(newParam);
			}
	}
 		| type_specifier ID
	{
			logWrite<<"parameter_list  : type_specifier ID"<<endl;
			$$ = new SymbolInfo("type_specifier ID", "parameter_list");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->addChild($1);
			$$->addChild($2);

			if($1->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line #"<<lineCount<<": Function parameter can not be void"<<endl;
			}
			else
			{
				$2->setTypeSpecifier($1->getTypeSpecifier());
				$$->addToParameterList($2);
				scopeParam.addToParameterList($2);
			}
	}
		| type_specifier
	{
		    logWrite<<"parameter_list  : type_specifier"<<endl;
			$$ = new SymbolInfo("type_specifier", "parameter_list");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			if($1->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line #"<<lineCount<<": Function parameter can not be void"<<endl;
			}
			else
			{
				SymbolInfo* param = new SymbolInfo("","ID");
				param->setTypeSpecifier($1->getTypeSpecifier());
				$$->addToParameterList(param);
				scopeParam.addToParameterList(param);
			}

	}
 		;

 		
compound_statement : LCURL statements RCURL
	{
				logWrite<<"compound_statement : LCURL statements RCURL"<<endl;
				$$ = new SymbolInfo("LCURL statements RCURL", "compound_statement");
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($3->getEndLine());
				$$->addChild($1); 
				$$->addChild($2);
				$$->addChild($3);
				Table->printAll(logWrite);
				Table->exitScope();
	}
 		    | LCURL RCURL
	{
		        logWrite<<"compound_statement : LCURL RCURL"<<endl;
				$$ = new SymbolInfo("LCURL RCURL", "compound_statement");
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($2->getEndLine());
				$$->addChild($1); 
				$$->addChild($2);
				Table->printAll(logWrite);
				Table->exitScope();
	}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			logWrite<<"var_declaration : type_specifier declaration_list SEMICOLON"<<endl;
			$$ = new SymbolInfo("type_specifier declaration_list SEMICOLON", "var_declaration");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);	

			vector<SymbolInfo*> vars = $2->getDeclarationList();									

			if($1->getSymbolName() == "VOID") 
			{
				for(auto var:vars) 
				{
					errorWrite<<"Line# "<<lineCount<<": Variable or field \'"<<var->getSymbolName()<<"\' declared void"<<endl; 
					ssErrorCount++;
				}
			} 
			else
			 {
				
				for(auto var:vars) 
				{
					SymbolInfo *symbol = new SymbolInfo(var->getSymbolName(),var->getSymbolType());
					symbol->setTypeSpecifier($1->getTypeSpecifier());
					symbol->setArrayStatus(var->getArrayStatus());
					bool success = Table->insertSymbol(symbol);
					if(!success)
					{
						SymbolInfo* checker = Table->lookupSymbol(symbol->getSymbolName());
						if(checker->getFunctionStatus())
						{
							errorWrite<<"Line# "<<lineCount<<": \'"<<symbol->getSymbolName()<<"\' redeclared as different kind of symbol"<<endl;
							ssErrorCount++;
						}
						else
						{
							errorWrite<<"Line# "<<lineCount<<": Conflicting types for \'"<<symbol->getSymbolName()<<"\'"<<endl;
							ssErrorCount++;
						}
					}
					
				}
				
			}
		}
		| type_specifier error SEMICOLON 
		 { 
			ssErrorCount++; 
			errorWrite<<"Line# "<<$1->getStartLine()<<": Syntax error at declaration list of variable declaration"<<endl;
			}
 		 ;
 		 
type_specifier	: INT
	{
	        logWrite<<"type_specifier	: INT"<<endl;
			$$ = new SymbolInfo("INT", "type_specifier");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);
			$$->setTypeSpecifier("INT");
		
	}
 		| FLOAT
	{
	        logWrite<<"type_specifier	: FLOAT"<<endl;
			$$ = new SymbolInfo("FLOAT", "type_specifier");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);
			$$->setTypeSpecifier("FLOAT");
		
	}
 		| VOID
	{
	        logWrite<<"type_specifier	: VOID"<<endl;
			$$ = new SymbolInfo("VOID", "type_specifier");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);
			$$->setTypeSpecifier("VOID");
		
	}
 		;
 		
declaration_list : declaration_list COMMA ID
		  {
			logWrite<<"declaration_list : declaration_list COMMA ID"<<endl;
			$$ = new SymbolInfo("declaration_list COMMA ID", "declaration_list");			
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			
			$$->setDeclarationList($1->getDeclarationList());			
			$$->addToDeclaration($3);
		}
		  
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		{
			logWrite<<"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE"<<endl;
			$$ = new SymbolInfo("declaration_list COMMA ID LSQUARE CONST_INT RSQUARE", "declaration_list");
			$3->setArrayStatus(true);
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($6->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5);
			$$->addChild($6);
			
			$$->setDeclarationList($1->getDeclarationList());
			$$->addToDeclaration($3);
		}
 		  | ID
		{
			logWrite<<"declaration_list : ID"<<endl;
			$$ = new SymbolInfo("ID", "declaration_list");			
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);
			$$->addToDeclaration($1);
		}
 		  | ID LTHIRD CONST_INT RTHIRD
		{			
			logWrite<<"declaration_list : ID LSQUARE CONST_INT RSQUARE"<<endl;	
			$$ = new SymbolInfo("ID LSQUARE CONST_INT RSQUARE", "declaration_list");		
			$1->setArrayStatus(true);	
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($4->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addToDeclaration($1);
		}
 		  ;
 		  
statements : statement
	{
			logWrite<<"statements : statement"<<endl;
			$$ = new SymbolInfo("statement", "statements");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);
	}
	   | statements statement
	{
			logWrite<<"statements : statements statement"<<endl;
			$$ = new SymbolInfo("statements statement", "statements");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
	}
	   ;
	   
statement : var_declaration
	{
			logWrite<<"statement : var_declaration"<<endl;
			$$ = new SymbolInfo("var_declaration", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);
	}
	  | expression_statement
	{
			logWrite<<"statement : expression_statement"<<endl;
			$$ = new SymbolInfo("expression_statement", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);
	}
	  | compound_statement
	{
			logWrite<<"statement : compound_statement"<<endl;
			$$ = new SymbolInfo("compound_statement", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);
	}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		    logWrite<<"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl;
			$$ = new SymbolInfo("FOR LPAREN expression_statement expression_statement expression RPAREN statement", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($7->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5);
			$$->addChild($6);
			$$->addChild($7);
	}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	{
		    logWrite<<"statement : IF LPAREN expression RPAREN statement"<<endl;
			$$ = new SymbolInfo("IF LPAREN expression RPAREN statement", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5);
	}
	  | IF LPAREN expression RPAREN statement ELSE statement
	{
		    logWrite<<"statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl;
			$$ = new SymbolInfo("IF LPAREN expression RPAREN statement ELSE statement", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($7->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5);
			$$->addChild($6);
			$$->addChild($7);
	}
	  | WHILE LPAREN expression RPAREN statement
	{
			logWrite<<"statement : WHILE LPAREN expression RPAREN statement"<<endl;
			$$ = new SymbolInfo("WHILE LPAREN expression RPAREN statement", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5);
	}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		    logWrite<<"statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl;
			$$ = new SymbolInfo("PRINTLN LPAREN ID RPAREN SEMICOLON", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($5->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);
			$$->addChild($5);

			if(Table->lookupSymbol($3->getSymbolName())==NULL)
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<lineCount<<": Undeclared variable \'"<<$3->getSymbolName()<<"\'"<<endl;
			}
	}
	  | RETURN expression SEMICOLON
	{
		    logWrite<<"statement : RETURN expression SEMICOLON"<<endl;
			$$ = new SymbolInfo("RETURN expression SEMICOLON", "statement");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);

			if($2->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Void cannot be used in expression"<<endl;
			}
	}
	  ;
	  
expression_statement 	: SEMICOLON	
	{
				logWrite<<"expression_statement : SEMICOLON"<<endl;
				$$ = new SymbolInfo("SEMICOLON", "expression_statement");
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($1->getEndLine());
				$$->addChild($1);
	}		
			| expression SEMICOLON 
	{
		        logWrite<<"expression_statement : expression SEMICOLON"<<endl;
				$$ = new SymbolInfo("expression SEMICOLON", "expression_statement");
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($2->getEndLine());
				$$->addChild($1);
				$$->addChild($2);

				$$->setTypeSpecifier($1->getTypeSpecifier());
				
	}
	| error SEMICOLON 
	{ 
		ssErrorCount++;
		errorWrite<<"Line# "<<$2->getStartLine()<<": Syntax error at expression of expression statement"<<endl;
		} 
			;
	  
variable : ID 	
	{
			logWrite<<"variable : ID"<<endl;
			$$ = new SymbolInfo("ID", "variable");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			SymbolInfo *symbol = Table->lookupSymbol($1->getSymbolName());
			if(symbol==nullptr)
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Undeclared variable '"<<$1->getSymbolName()<<"'"<<endl;
			}
			else if(symbol->getFunctionStatus())
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": '"<<symbol->getSymbolName()<<"' is declared as function"<<endl;
			}
			else
			{
				$$->setTypeSpecifier(symbol->getTypeSpecifier());
			}
	}	
	 | ID LTHIRD expression RTHIRD 
	{
			logWrite<<"variable : ID LSQUARE expression RSQUARE"<<endl;
			$$ = new SymbolInfo("ID LSQUARE expression RSQUARE", "variable");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($4->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);

			SymbolInfo *symbol = Table->lookupSymbol($1->getSymbolName());
			if(symbol==nullptr)
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Undeclared variable '"<<$1->getSymbolName()<<"'"<<endl;
			}
			else if(symbol->getArrayStatus()==false)
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": '"<<symbol->getSymbolName()<<"' is not an array"<<endl;
			}
			else if($3->getTypeSpecifier()!="INT")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Array subscript is not an integer"<<endl;
			}
			else if(symbol->getFunctionStatus())
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": '"<<symbol->getSymbolName()<<"' is declared as function"<<endl;
			}
			else
			{
				$$->setTypeSpecifier(symbol->getTypeSpecifier());
				$$->setArrayStatus(true);
			}
	}
	 ;
	 
 expression : logic_expression	
	{
			logWrite<<"expression : logic_expression"<<endl;
			$$ = new SymbolInfo("logic_expression", "expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier($1->getTypeSpecifier());
			$$->setArrayStatus($1->getArrayStatus());
			
	}
	   | variable ASSIGNOP logic_expression 	
	{
			logWrite<<"expression : variable ASSIGNOP logic_expression"<<endl;
			$$ = new SymbolInfo("variable ASSIGNOP logic_expression", "expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);

			if($1->getTypeSpecifier()=="VOID" || $3->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$2->getStartLine()<<": Void cannot be used in expression"<<endl;
			}
			
			else if($1->getTypeSpecifier()=="INT" && $3->getTypeSpecifier()=="FLOAT")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$2->getStartLine()<<": Warning: possible loss of data in assignment of FLOAT to INT"<<endl;
			}
			else
			{
				$$->setTypeSpecifier($1->getTypeSpecifier());
			}
	}
	   ;
			
logic_expression : rel_expression 	
	{
			logWrite<<"logic_expression : rel_expression"<<endl;
			$$ = new SymbolInfo("rel_expression", "logic_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier($1->getTypeSpecifier());
			$$->setArrayStatus($1->getArrayStatus());
	}
		 | rel_expression LOGICOP rel_expression 	
	{
		    logWrite<<"logic_expression : rel_expression LOGICOP rel_expression"<<endl;
			$$ = new SymbolInfo("rel_expression LOGICOP rel_expression", "logic_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);

			if($1->getTypeSpecifier()=="VOID" || $3->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$2->getStartLine()<<": Void cannot be used in expression"<<endl;
			}			
			else
			{
				$$->setTypeSpecifier("INT");
			}
	}
		 ;
			
rel_expression	: simple_expression 
	{
			logWrite<<"rel_expression : simple_expression"<<endl;
			$$ = new SymbolInfo("simple_expression", "rel_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier($1->getTypeSpecifier());
			$$->setArrayStatus($1->getArrayStatus());
	}
		| simple_expression RELOP simple_expression	
	{
			logWrite<<"rel_expression : simple_expression RELOP simple_expression"<<endl;
			$$ = new SymbolInfo("simple_expression RELOP simple_expression", "rel_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);

			if($1->getTypeSpecifier()=="VOID" || $3->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$2->getStartLine()<<": Void cannot be used in expression"<<endl;
			}
			else
			{
				$$->setTypeSpecifier("INT");
			}
	}
		;
				
simple_expression : term 
	{
			logWrite<<"simple_expression : term"<<endl;
			$$ = new SymbolInfo("term", "simple_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier($1->getTypeSpecifier());
			$$->setArrayStatus($1->getArrayStatus());
	}
		  | simple_expression ADDOP term 
	{
			logWrite<<"simple_expression : simple_expression ADDOP term"<<endl;
			$$ = new SymbolInfo("simple_expression ADDOP term", "simple_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);

			if($1->getTypeSpecifier()=="VOID" || $3->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$2->getStartLine()<<": Void cannot be used in expression"<<endl;
			}
			else if($1->getTypeSpecifier()=="FLOAT" || $3->getTypeSpecifier()=="FLOAT")
			{
				$$->setTypeSpecifier("FLOAT");
			}
			else
			{
				$$->setTypeSpecifier("INT");
			}
	}
		  ;
					
term :	unary_expression
	{
			logWrite<<"term : unary_expression"<<endl;
			$$ = new SymbolInfo("unary_expression", "term");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier($1->getTypeSpecifier());
			$$->setArrayStatus($1->getArrayStatus());
	}
     |  term MULOP unary_expression
	{
			logWrite<<"term : term MULOP unary_expression"<<endl;
			$$ = new SymbolInfo("term MULOP unary_expression", "term");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);

			if($1->getTypeSpecifier()=="VOID" || $3->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$2->getStartLine()<<": Void cannot be used in expression"<<endl;
			}
			else if($2->getSymbolName()=="%" && $3->getTypeSpecifier()!="INT")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$2->getStartLine()<<": Operands of modulus must be integers"<<endl;
			}
			else if(($2->getSymbolName()=="%" || $2->getSymbolName()=="/" ) && $3->getZeroStatus())
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$2->getStartLine()<<": Warning: division by zero"<<endl;
			}
			else if($1->getTypeSpecifier()=="FLOAT" || $3->getTypeSpecifier()=="FLOAT")
			{
				$$->setTypeSpecifier("FLOAT");
			}
			else
			{
				$$->setTypeSpecifier("INT");
			}
			
	}		
     ;

unary_expression : ADDOP unary_expression  
	{
			logWrite<<"unary_expression : ADDOP unary_expression"<<endl;
			$$ = new SymbolInfo("ADDOP unary_expression", "unary_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->addChild($1);
			$$->addChild($2);

			if($2->getTypeSpecifier()=="VOID")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Void cannot be used in expression"<<endl;
			}
			else 
			{
				$$->setTypeSpecifier($2->getTypeSpecifier());
			}
	}
		 | NOT unary_expression 
    {
			logWrite<<"unary_expression : NOT unary_expression"<<endl;
			$$ = new SymbolInfo("NOT unary_expression", "unary_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->addChild($1);
			$$->addChild($2);

			if($2->getTypeSpecifier()!="INT")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Operands of '!' must be integers"<<endl;
			}
			else 
			{
				$$->setTypeSpecifier($2->getTypeSpecifier());
			}
	}
		 | factor 
	{
		    logWrite<<"unary_expression : factor"<<endl;
			$$ = new SymbolInfo("factor", "unary_expression");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier($1->getTypeSpecifier());
			$$->setArrayStatus($1->getArrayStatus());
			$$->setZeroStatus($1->getZeroStatus());
	}
		 ;
	
factor	: variable 
	{
			logWrite<<"factor : variable"<<endl;
			$$ = new SymbolInfo("variable", "factor");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier($1->getTypeSpecifier());
			$$->setArrayStatus($1->getArrayStatus());
	}
	| ID LPAREN argument_list RPAREN
	{
			logWrite<<"factor : ID LPAREN argument_list RPAREN"<<endl;
			$$ = new SymbolInfo("ID LPAREN argument_list RPAREN", "factor");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($4->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			$$->addChild($4);

			SymbolInfo *symbol = Table->lookupSymbol($1->getSymbolName());
			if(symbol==nullptr)
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Undeclared function '"<<$1->getSymbolName()<<"'"<<endl;
			}
			else
			{
			  $$->setTypeSpecifier(symbol->getTypeSpecifier());
			  if(symbol->getFunctionStatus()==false)
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": '"<<$1->getSymbolName()<<"' is not a function"<<endl;
			}
			else
			{
				vector <SymbolInfo*> params = symbol->getParameterList();
				vector<SymbolInfo*> args = $3->getParameterList();
				if(params.size() > args.size())
				{
					ssErrorCount++;
					errorWrite<<"Line# "<<$1->getStartLine()<<": Too few arguments to function '"<<$1->getSymbolName()<<"'"<<endl;
				}
				else if(params.size() < args.size())
				{
					ssErrorCount++;
					errorWrite<<"Line# "<<$1->getStartLine()<<": Too many arguments to function '"<<$1->getSymbolName()<<"'"<<endl;
				}
				else
				{
					for(int i =0;i<params.size();i++)
					{
						if(params[i]->getTypeSpecifier()!=args[i]->getTypeSpecifier())
						{
							ssErrorCount++;
							errorWrite<<"Line# "<<$$->getStartLine()<<": Type mismatch for argument"<< i+1<<" of \'"<<$1->getSymbolName()<<"\'"<<endl;
						}
						
					}
				}
			}
			
			
			}
			
	}
	| LPAREN expression RPAREN
	{
			logWrite<<"factor : LPAREN expression RPAREN"<<endl;
			$$ = new SymbolInfo("LPAREN expression RPAREN", "factor");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);
			
			$$->setTypeSpecifier($2->getTypeSpecifier());
			$$->setArrayStatus($2->getArrayStatus());
	}
	| CONST_INT 
	{
			logWrite<<"factor : CONST_INT"<<endl;
			$$ = new SymbolInfo("CONST_INT", "factor");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier("INT");
			if($1->getSymbolName()=="0")
			{
				$$->setZeroStatus(true);
			}

	}
	| CONST_FLOAT
	{
			logWrite<<"factor : CONST_FLOAT"<<endl;
			$$ = new SymbolInfo("CONST_FLOAT", "factor");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->setTypeSpecifier("FLOAT");
	}
	| variable INCOP 
	{
			logWrite<<"factor : variable INCOP"<<endl;
			$$ = new SymbolInfo("variable INCOP", "factor");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->addChild($1);
			$$->addChild($2);

			if($1->getTypeSpecifier()!="INT")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Invalid type of operand for decrement operator"<<endl;
			}
			else
			{
				$$->setTypeSpecifier($1->getTypeSpecifier());
			}
	}
	| variable DECOP
	{
			logWrite<<"factor : variable DECOP"<<endl;
			$$ = new SymbolInfo("variable DECOP", "factor");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->addChild($1);
			$$->addChild($2);

			if($1->getTypeSpecifier()!="INT")
			{
				ssErrorCount++;
				errorWrite<<"Line# "<<$1->getStartLine()<<": Invalid type of operand for increment operator"<<endl;
			}
			else
			{
				$$->setTypeSpecifier($1->getTypeSpecifier());
			}
	}
	;
	
argument_list : arguments
	{
				logWrite<<"argument_list : arguments"<<endl;
				$$ = new SymbolInfo("arguments", "argument_list");
				$$->setStartLine($1->getStartLine());
				$$->setEndLine($1->getEndLine());
				$$->addChild($1);

				$$->setParameterList($1->getParameterList());
	}
			  |
	{
				logWrite<<"argument_list"<<endl;
				$$ = new SymbolInfo("", "argument_list");
				$$->setStartLine(lineCount);
				$$->setEndLine(lineCount);
	}
			  ;
	
arguments : arguments COMMA logic_expression
	{
			logWrite<<"arguments : arguments COMMA logic_expression"<<endl;
			$$ = new SymbolInfo("arguments COMMA logic_expression", "arguments");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild($1);
			$$->addChild($2);
			$$->addChild($3);

			$$->setParameterList($1->getParameterList());
			$$->addToParameterList($3);
	}
	
	      | logic_expression
	{
			logWrite<<"arguments : logic_expression"<<endl;
			$$ = new SymbolInfo("logic_expression", "arguments");
			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild($1);

			$$->addToParameterList($1);
			
	}
	      ;
 

%%
int main(int argc,char *argv[])
{
	FILE *fp;
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logWrite.open("log.txt");
	errorWrite.open("error.txt");
	ptWrite.open("parsetree.txt");
	
	yyin=fp;
	yyparse();
	
	fclose(yyin);
	logWrite.close();
	errorWrite.close();
	ptWrite.close();
	
	return 0;
}

