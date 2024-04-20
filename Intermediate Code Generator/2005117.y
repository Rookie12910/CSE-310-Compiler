
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
ofstream codeWrite;
ofstream optWrite;

SymbolTable *Table = new SymbolTable(total_buckets);
SymbolInfo scopeParam;
SymbolInfo *start;



vector<SymbolInfo*> globalVars;
vector<SymbolInfo*> localParams;
int labelCounter = 1;
bool isGlobal = true; 
int stackOffset = 0;
string retLabel = "";

void yyerror(string s)
{
	logWrite<<"Error at line no "<<lineCount<<": "<<s<<endl;
}


string createLabel(){
	labelCounter++;
	string label = "L"+ to_string(labelCounter);
	return label ;
}


void printFunction()
{
	string label = createLabel();
	codeWrite<<label<<":"<<endl;
	codeWrite<<"new_line proc\n\tpush ax\n\tpush dx\n\tmov ah,2\n\tmov dl,0Dh\n\tint 21h\n\tmov ah,2\n\tmov dl,0Ah\n\tint 21h\n\tpop dx\n\tpop ax\n\tret\nnew_line endp\nprint_output proc  ;print what is in ax\n\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n\tpush si\n\tlea si,number\n\tmov bx,10\n\tadd si,4\n\tcmp ax,0\n\tjnge negate\n\tprint:\n\txor dx,dx\n\tdiv bx\n\tmov [si],dl\n\tadd [si],'0'\n\tdec si\n\tcmp ax,0\n\tjne print\n\tinc si\n\tlea dx,si\n\tmov ah,9\n\tint 21h\n\tpop si\n\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\tret\n\tnegate:\n\tpush ax\n\tmov ah,2\n\tmov dl,'-'\n\tint 21h\n\tpop ax\n\tneg ax\n\tjmp print\nprint_output endp\n\tEND main"<<endl;
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


void Optimize(){
	ifstream unOptFile;
	unOptFile.open("2005117_code.asm");
	string codeLine = "";
	vector<string> unOptCode;

	while(getline(unOptFile, codeLine))
	{
		unOptCode.push_back(codeLine);
	}
	
	for(int i=0; i < unOptCode.size(); i++)
	{
		 if(unOptCode[i].substr(1,3) == "ADD" || unOptCode[i].substr(1,3) == "SUB")
		 {
			string temp = unOptCode[i];
			int index = temp.find(",");
			if(temp.substr(index+2) == "0"){
				optWrite << "\t\t" << ";Unnecessary ADD/SUB has been removed" << endl;
				continue;
			}
		 }
		
		else if(unOptCode[i].substr(1,3) == "MOV" && unOptCode[i+1].substr(1,3) == "MOV")
		{
			
			string temp1 = unOptCode[i].substr(4);
			string temp2 = unOptCode[i+1].substr(4);
			int index1 = temp1.find(",");
			int index2 = temp2.find(",");

			if((temp1.substr(1,index1 - 1) == (temp2.substr(index2 + 2))) && (temp1.substr(index1 + 2) == (temp2.substr(1,index2 - 1))))
			{
				optWrite << "\t\t" << ";Redundant MOV instruction has been removed " << endl;
				optWrite << unOptCode[i] << endl;
				i++;
				continue;
			}

		}
		else if(unOptCode[i].substr(1,4) == "PUSH" && unOptCode[i+1].substr(1,3) == "POP")
		{
			string temp1 = unOptCode[i];
			string temp2 = unOptCode[i+1];

			if(temp1.substr(6) == temp2.substr(5))
			{
				optWrite << "\t\t" << ";Unnecessary PUSH POP instructions have been removed " << endl;
				i++;
				continue;
			}
		}

		optWrite << unOptCode[i] << endl;
	}
}


void generateCode(SymbolInfo *symbol)
{
	
    if(symbol->getLeafStatus())
	{
		if(symbol->getSymbolType()=="LCURL")
		{
			
			Table->enterScope();
			for(int i =0;i<localParams.size();i++)
			{
				SymbolInfo* param = new SymbolInfo(localParams[i]->getSymbolName(),localParams[i]->getSymbolType());
				param->setOffset(localParams[i]->getOffset());
				param->setGlobalStatus(false);
				bool flag = Table->insertSymbol(param);
			}
		}
		if(symbol->getSymbolType()=="RCURL")
		{
			Table->exitScope();
		}
		
		return;
		
	}
	
	else
	{
		
		
		//START

		if(symbol->getSymbolType()=="start")
		{
			codeWrite<<".MODEL SMALL\n.STACK 1000H\n.Data"<<endl;
			codeWrite<<"\tnumber DB \"00000$\""<<endl;
			for(auto var : globalVars)
			{
				if(var->getArrayStatus())
				{
					codeWrite<<'\t'<<var->getSymbolName()<<" DW "<<var->getArraySize()<<" DUP (0000H)"<<endl;
				}
				else
				{
					codeWrite<<'\t'<<var->getSymbolName()<<" DW 1 DUP (0000H)"<<endl;
				}
				
			}
			codeWrite<<".CODE"<<endl;

			for( auto child : symbol->getChildren())
			{

			generateCode(child);
			
			}
			return;
		}



		//FUNC_DEFINITION

		else if (symbol->getSymbolType()=="func_definition")
		{
			localParams.clear();
			stackOffset = 0;
			vector<SymbolInfo*> children = symbol->getChildren();
			codeWrite<<children[1]->getSymbolName()<<" PROC"<<endl;
			if(children[1]->getSymbolName()=="main")
			{	
				codeWrite<<"\tMOV AX, @DATA\n\tMOV DS, AX"<<endl;
			}
			codeWrite<<"\tPUSH BP\n\tMOV BP, SP"<<endl;
			retLabel = createLabel();

			if(symbol->getSymbolName()=="type_specifier ID LPAREN parameter_list RPAREN compound_statement")
			{
				stackOffset-=2;
				for(int i=0; i<(symbol->getChildren()[3]->getParameterList().size()); i++)
				{
				localParams.push_back(symbol->getChildren()[3]->getParameterList()[i]);
				stackOffset -= 2;
				localParams[i]->setOffset(stackOffset);
				}
			}

			stackOffset = 0;
			
			for( auto child : symbol->getChildren())
			{
				generateCode(child);
			}

			
			codeWrite << retLabel << ":" << endl;
			codeWrite << "\tADD SP, " << stackOffset << endl;
			codeWrite << "\tMOV SP, BP" << endl;			
			codeWrite << "\t" << "POP BP" << endl;

			if(children[1]->getSymbolName()=="main")
			{	
				codeWrite<<"\tMOV AX, 4CH\n\tINT 21H\n";
				codeWrite<<children[1]->getSymbolName()<<" ENDP"<<endl;
				printFunction();
			}
			else
			{
				codeWrite<<"\tRET "<<children[3]->getParameterList().size()*2<<endl; 
				codeWrite<<children[1]->getSymbolName()<<" ENDP"<<endl;
			}
			
			stackOffset = 0;

			return;
		}


		//COMPOUND_STATEMENT

		else if(symbol->getSymbolType()=="compound_statement")
		{
			isGlobal = false;
			for( auto child : symbol->getChildren())
			{
				generateCode(child);	
			}
			isGlobal = true;
			return;

		}
		

		//VAR_DECLARATION

		else if(symbol->getSymbolType()=="var_declaration")	
		{
			
			if(!isGlobal)
			{	

			string label = createLabel();
			codeWrite<<label<<":"<<endl;

			vector<SymbolInfo*> children = symbol->getChildren();
			SymbolInfo *type = children[0];
			vector<SymbolInfo*> declarationList = children[1]->getDeclarationList();
			if(type->getSymbolName()=="INT")
			{
				for(int i = 0; i<declarationList.size();i++)
				{
					if(declarationList[i]->getArrayStatus())
					{
						codeWrite<<"\tSUB SP, "<<2*declarationList[i]->getArraySize()<<endl;
						stackOffset+=2*declarationList[i]->getArraySize();
					}
					else
					{
						codeWrite<<"\tSUB SP, 2\n";
					    stackOffset+=2;
					}
			
					SymbolInfo *var = new SymbolInfo(declarationList[i]->getSymbolName(),declarationList[i]->getSymbolType());
					var->setTypeSpecifier(declarationList[i]->getTypeSpecifier());
					var->setArrayStatus(declarationList[i]->getArrayStatus());
					var->setArraySize(declarationList[i]->getArraySize());
					var->setOffset(stackOffset);
					Table->insertSymbol(var);			
				}
					
			}
			else if(type->getSymbolName()=="FLOAT")
			{
				for(int i = 0; i<declarationList.size();i++)
				{
					if(declarationList[i]->getArrayStatus())
					{
						codeWrite<<"\tSUB SP, "<<4*declarationList[i]->getArraySize()<<endl;
						stackOffset+=4*declarationList[i]->getArraySize();
					}
					else
					{
						codeWrite<<"\tSUB SP, 4\n";
						stackOffset+=4;
					}
					
					SymbolInfo *var = new SymbolInfo(declarationList[i]->getSymbolName(),declarationList[i]->getSymbolType());
					var->setTypeSpecifier(declarationList[i]->getTypeSpecifier());
					var->setArrayStatus(declarationList[i]->getArrayStatus());
					var->setOffset(stackOffset);
					Table->insertSymbol(var);
				}
			}
				return;
			}
			
			for( auto child : symbol->getChildren())
			{
				generateCode(child);	
			}
			return;
		}


		
		
		
		//STATEMENT

		else if(symbol->getSymbolType()=="statement")
		{
			
			if(symbol->getSymbolName()=="PRINTLN LPAREN ID RPAREN SEMICOLON")
			{
				SymbolInfo* ID = Table->lookupSymbol(symbol->getChildren()[2]->getSymbolName());
				if(ID->getGlobalStatus()){
					codeWrite << "\tMOV AX, " << ID->getSymbolName() << endl;
				}
				else{
					codeWrite << "\tMOV AX, [BP- " << ID->getOffset() << "]" << endl;
				}
						
				codeWrite << "\tCALL print_output" << endl;
				codeWrite << "\tCALL new_line" << endl;
				return;
			}


			if(symbol->getSymbolName()=="WHILE LPAREN expression RPAREN statement")
			{
				string endLabel = createLabel();
				string loopLabel = createLabel();

				codeWrite << loopLabel << ":" << endl;
				generateCode(symbol->getChildren()[2]);
				codeWrite << "\t" << "POP AX" << endl;
				codeWrite << "\t" << "CMP AX,0" << endl;
				codeWrite << "\t" << "JE " << endLabel << endl;
				generateCode(symbol->getChildren()[4]);
				codeWrite << "\t" << "JMP " << loopLabel << endl;
				codeWrite << endLabel << ":" << endl;
				return;
			}

			if(symbol->getSymbolName()=="FOR LPAREN expression_statement expression_statement expression RPAREN statement")
			{
				string loopLabel = createLabel();
				string skipLabel = createLabel();
				string endLabel = createLabel();

				codeWrite << "\t\t" << ";Line no# " <<symbol->getStartLine()<< ": FOR loop starts " << endl;

				generateCode(symbol->getChildren()[2]);

				codeWrite << loopLabel << ":" << endl;
				generateCode(symbol->getChildren()[3]);
				codeWrite << "\t" << "POP AX" << endl;
				codeWrite << "\t" << "CMP AX, 0" << endl;
				codeWrite << "\t" << "JE " << endLabel << endl;

				generateCode(symbol->getChildren()[6]);

				generateCode(symbol->getChildren()[4]);
				codeWrite << "\t" << "JMP " << loopLabel << endl;

				codeWrite << endLabel << ":" << endl;

				codeWrite << "\t\t" << ";Line no# " << symbol->getEndLine() << ": FOR loop ends " << endl;
				return;
			}

			if(symbol->getSymbolName()=="IF LPAREN expression RPAREN statement")
			{
				string endLabel = createLabel();

				codeWrite << "\t\t" << ";Line no# " << symbol->getStartLine() << ": IF block starts " << endl;
				generateCode(symbol->getChildren()[2]);
				codeWrite << "\t" << "POP AX" << endl;
				codeWrite << "\t" << "CMP AX,0" << endl;
				codeWrite << "\t" << "JE " << endLabel << endl;

				generateCode(symbol->getChildren()[4]);

				codeWrite << endLabel << ":" << endl;

				codeWrite << "\t\t" << ";Line no# " << symbol->getEndLine() << ": IF block ends " << endl;
				return;
			}

			if(symbol->getSymbolName()=="IF LPAREN expression RPAREN statement ELSE statement")
			{
				string elseLabel = createLabel();
				string skipLabel = createLabel();

				codeWrite << "\t\t" << ";Line no# " << symbol->getStartLine() << ": if-else block starts " << endl;
				generateCode(symbol->getChildren()[2]);
				codeWrite << "\t" << "POP AX" << endl;
				codeWrite << "\t" << "CMP AX,0" << endl;
				codeWrite << "\t" << "JE " << elseLabel << endl;
				generateCode(symbol->getChildren()[4]);
				codeWrite << "\t" << "JMP " << skipLabel << endl;
				codeWrite << elseLabel << ":" << endl;
				generateCode(symbol->getChildren()[6]);
				codeWrite << skipLabel << ":" << endl;
				codeWrite << "\t\t" << ";Line no# " << symbol->getEndLine() << ": if-else block ends " << endl;
				return;
			}
			
			if(symbol->getSymbolName()=="RETURN expression SEMICOLON")
			{
				generateCode(symbol->getChildren()[1]);
				codeWrite << "\t" << "POP CX" << endl;
				codeWrite << "\t" << "JMP " << retLabel << endl;
				return;
			}

			for( auto child : symbol->getChildren())
			{
				generateCode(child);	
			}
			return;
		}



		//VARIABLE

		else if(symbol->getSymbolType()=="variable")
		{
			if(symbol->getSymbolName()=="ID")
			{
				SymbolInfo* ID = Table->lookupSymbol(symbol->getChildren()[0]->getSymbolName());
				
				if(ID->getGlobalStatus()){
					codeWrite << "\t\t" << ";Line no# " << symbol->getStartLine() << ": global var " << endl;
					codeWrite << "\t" << "MOV AX, " << ID->getSymbolName() << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
				}
				else{
					codeWrite << "\t\t" << ";Line no# " << symbol->getStartLine() << ": local var " << endl;
					codeWrite << "\t" << "MOV AX, [BP- " << ID->getOffset() << "]" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
		}
			return;
			}

			if(symbol->getSymbolName()=="ID LTHIRD expression RTHIRD")
			{
				
				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}

				SymbolInfo* ID = Table->lookupSymbol(symbol->getChildren()[0]->getSymbolName());
				
				if(ID->getGlobalStatus())
				{
					
					codeWrite << "\tPOP AX" << endl;
					codeWrite << "\t\t" << ";Line no# " <<symbol->getStartLine()<< ": global array " << endl;
					codeWrite << "\tLEA SI," << ID->getSymbolName() << endl;
					codeWrite << "\tADD SI, AX" << endl;
					codeWrite << "\tADD SI, AX" << endl;
					codeWrite << "\tMOV AX, [SI]" << endl;
					codeWrite << "\tPUSH AX" << endl;
				}
				else
				{
					
					codeWrite << "\tPOP BX" << endl;
					codeWrite << "\t\t" << ";Line no# " << symbol->getStartLine() << ": local array " << endl;

					codeWrite << "\tMOV AX, 2" << endl;
					codeWrite << "\t" << "CWD" << endl;
					codeWrite << "\t" << "IMUL BX" << endl;
					codeWrite << "\tMOV BX, AX" << endl;
					codeWrite << "\tADD BX, " << ID->getOffset() << endl;
					
					codeWrite << "\t" << "PUSH DI" << endl;
					codeWrite << "\t" << "MOV DI, BX" << endl;	
					codeWrite << "\t" << "NEG DI" << endl;		
					codeWrite << "\t" << "MOV AX, [BP+DI]" << endl;
					codeWrite << "\t" << "POP DI" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
				}
				return;
			}

				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}
				return;
			
			
		}


		//EXPRESSION

		else if(symbol->getSymbolType()=="expression")
		{
			
			if(symbol->getSymbolName()=="variable ASSIGNOP logic_expression")
			{
				for( auto child : symbol->getChildren())
			{
				generateCode(child);	
			}

			codeWrite << "\t" << "POP AX" << endl;
			codeWrite << "\t" << "POP BX" << endl;
			codeWrite << "\tMOV CX, AX" << endl;
					
				string varName = symbol->getChildren()[0]->getChildren()[0]->getSymbolName();
				SymbolInfo* var = Table->lookupSymbol(varName);
				if(var->getGlobalStatus())
				{
					if(var->getArrayStatus())
					{
						codeWrite << "\t" << "PUSH AX" << endl;
						generateCode(symbol->getChildren()[0]->getChildren()[2]);
						codeWrite << "\t" << "POP DX" << endl;
						codeWrite << "\t" << "POP AX" << endl;
						codeWrite << "\t" << "LEA SI," << var->getSymbolName() << endl;
						codeWrite << "\t" << "ADD SI, DX" << endl;
						codeWrite << "\t" << "ADD SI, DX" << endl;
						codeWrite << "\t" << "MOV [SI], AX" << endl;
					}
					else
					{
						codeWrite<<"\tMOV "<<varName<<", AX\n";
					}
				}
				else
				{
					if(var->getArrayStatus())
					{
						generateCode(symbol->getChildren()[0]->getChildren()[2]);
						codeWrite << "\tPOP BX" << endl;

						codeWrite << "\tMOV AX, 2" << endl;
						codeWrite << "\t" << "CWD" << endl;
						codeWrite << "\t" << "IMUL BX" << endl;
						codeWrite << "\tMOV BX, AX" << endl;
						codeWrite << "\tADD BX," << var->getOffset() << endl;
						
						codeWrite << "\t" << "PUSH DI" << endl;
						codeWrite << "\t" << "MOV DI, BX" << endl;
						codeWrite << "\t" << "NEG DI" << endl;
						codeWrite << "\t" << "MOV [BP+DI], CX" << endl;
						codeWrite << "\t" << "POP DI" << endl;
					}
					else
					{
						codeWrite<<"\tMOV [BP-"<<var->getOffset()<<"], AX\n";
					}
				}

			 	return;
			}

			for( auto child : symbol->getChildren())
			{
				generateCode(child);	
			}
			return;
		}


		//LOGIC_EXPRESSION

		else if(symbol->getSymbolType()=="logic_expression")
		{
			if(symbol->getSymbolName()=="rel_expression LOGICOP rel_expression")
			{
				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}

			codeWrite << "\t" << "POP AX" << endl;
			codeWrite << "\t" << "POP BX" << endl;

			string trueLabel = createLabel();
			string falseLabel = createLabel();
			string skipLabel = createLabel();

			if(symbol->getChildren()[1]->getSymbolName() == "&&"){
				string nextLabel = createLabel();
				codeWrite << "\t" << "CMP BX,0" << endl;
				codeWrite << "\t" << "JNE " << nextLabel << endl;
				codeWrite << "\t" << "JMP " << falseLabel << endl;

				codeWrite << nextLabel << ":" << endl;
				codeWrite << "\t" << "CMP AX,0" << endl;
				codeWrite << "\t" << "JNE " << trueLabel << endl;
				codeWrite << "\t" << "JMP " << falseLabel << endl;
			}
			else if(symbol->getChildren()[1]->getSymbolName() == "||"){
				codeWrite << "\t" << "CMP BX,0" << endl;
				codeWrite << "\t" << "JNE " << trueLabel << endl;

				codeWrite << "\t" << "CMP AX,0" << endl;
				codeWrite << "\t" << "JNE " << trueLabel << endl;
				codeWrite << "\t" << "JMP " << falseLabel << endl;
			}

			codeWrite << trueLabel << ":" << endl;
			codeWrite << "\t" << "MOV AX, 1" << endl;
			codeWrite << "\t" << "JMP " << skipLabel << endl;

			codeWrite << falseLabel << ":" << endl;
			codeWrite << "\t" << "MOV AX, 0" << endl;
			
			codeWrite << skipLabel << ":" << endl;
			codeWrite << "\t" << "PUSH AX" << endl;

				return;
			}

			for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}
			return;
		}


		//REL_EXPRESSSION

		else if(symbol->getSymbolType()=="rel_expression")
		{

			if(symbol->getSymbolName()=="simple_expression RELOP simple_expression")
			{
				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}
				codeWrite << "\t" << "POP AX" << endl;
				codeWrite << "\t" << "POP BX" << endl;
				codeWrite << "\t\t" << ";Line no# " << symbol->getStartLine() << endl;

				string trueLabel = createLabel();

				string skipLabel = createLabel();	

				if(symbol->getChildren()[1]->getSymbolName() == "<"){
					codeWrite << "\t" << "CMP BX,AX" << endl;
					codeWrite << "\t" << "JL " << trueLabel << endl;
					codeWrite << "\t" << "MOV AX, 0" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
					codeWrite << "\t" << "JMP " << skipLabel << endl; 
				}
				else if(symbol->getChildren()[1]->getSymbolName() == "<="){
					codeWrite << "\t" << "CMP BX,AX" << endl;
					codeWrite << "\t" << "JLE " << trueLabel << endl;
					codeWrite << "\t" << "MOV AX, 0" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
					codeWrite << "\t" << "JMP " << skipLabel << endl; 
				}
				else if(symbol->getChildren()[1]->getSymbolName() == ">"){
					codeWrite << "\t" << "CMP BX,AX" << endl;
					codeWrite << "\t" << "JG " << trueLabel << endl;
					codeWrite << "\t" << "MOV AX, 0" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
					codeWrite << "\t" << "JMP " << skipLabel << endl;
				}
				else if(symbol->getChildren()[1]->getSymbolName() == ">="){
					codeWrite << "\t" << "CMP BX,AX" << endl;
					codeWrite << "\t" << "JGE " << trueLabel << endl;
					codeWrite << "\t" << "MOV AX, 0" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
					codeWrite << "\t" << "JMP " << skipLabel << endl;
				}
				else if(symbol->getChildren()[1]->getSymbolName() =="=="){
					codeWrite << "\t" << "CMP BX,AX" << endl;
					codeWrite << "\t" << "JE " << trueLabel << endl;
					codeWrite << "\t" << "MOV AX, 0" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
					codeWrite << "\t" << "JMP " << skipLabel << endl; 
				}
				else if(symbol->getChildren()[1]->getSymbolName() == "!="){
					codeWrite << "\t" << "CMP BX, AX" << endl;
					codeWrite << "\t" << "JNE " << trueLabel << endl;
					codeWrite << "\t" << "MOV AX, 0" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
					codeWrite << "\t" << "JMP " << skipLabel << endl; 
				}

				codeWrite << trueLabel << ":" << endl;
				codeWrite << "\t" << "MOV AX, 1" << endl;
				codeWrite << "\t" << "PUSH AX" << endl;

				codeWrite << skipLabel << ":" << endl;
				return;
			}

			for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}
			return;
		}


		//SIMPLE_EXPRESSION

		else if(symbol->getSymbolType()=="simple_expression")
		{
			
			if(symbol->getSymbolName()=="simple_expression ADDOP term")
			{
				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}

				codeWrite << "\t" << "POP AX" << endl;
				codeWrite << "\t" << "POP BX" << endl;
				codeWrite << "\t\t" << ";Line no# " <<symbol->getStartLine() << ": ADDOP found" << endl;

				if(symbol->getChildren()[1]->getSymbolName() == "+"){
					codeWrite << "\t" << "ADD AX, BX" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
				}
				else if(symbol->getChildren()[1]->getSymbolName() == "-"){
					codeWrite << "\t" << "SUB BX, AX" << endl;
					codeWrite << "\t" << "PUSH BX" << endl;
				}
				return;
			}

			for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}
			return;
		}


		//TERM

		else if(symbol->getSymbolType()=="term")
		{
			if(symbol->getSymbolName()=="term MULOP unary_expression")
			{
				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}
				if(symbol->getChildren()[1]->getSymbolName()=="*")
				{
					codeWrite << "\t" << "POP AX" << endl;
					codeWrite << "\t" << "POP CX" << endl;
					codeWrite << "\t" << "CWD" << endl;
					codeWrite << "\t" << "IMUL CX" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
				}
				else if(symbol->getChildren()[1]->getSymbolName()=="/"){
					codeWrite << "\t" << "POP BX" << endl;
					codeWrite << "\t" << "POP AX" << endl;
					codeWrite << "\t" << "CWD" << endl;
					codeWrite << "\t" << "IDIV BX" << endl;
					codeWrite << "\t" << "PUSH AX" << endl;
				}
				else if(symbol->getChildren()[1]->getSymbolName()=="%"){
					codeWrite << "\t" << "POP BX" << endl;
					codeWrite << "\t" << "POP AX" << endl;
					codeWrite << "\t" << "CWD" << endl;
					codeWrite << "\t" << "IDIV BX" << endl;
					codeWrite << "\t" << "PUSH DX" << endl;
			}
				
				return;
			}

				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}
				return;
		}


		//UNARY_EXPRESSION

		else if(symbol->getSymbolType()=="unary_expression")
		{
			if(symbol->getSymbolName()=="ADDOP unary_expression")
			{
				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}

				codeWrite << "\t" << "POP AX" << endl;
				codeWrite << "\t\t" << ";Line no# " << symbol->getStartLine() << ": ADDOP unary_exp " << endl;

				if(symbol->getChildren()[0]->getSymbolName() == "-"){
					codeWrite << "\t" << "NEG AX" << endl;
				}
				codeWrite << "\t" << "PUSH AX" << endl;

				return;
			}


			if(symbol->getSymbolName()=="NOT unary_expression")
			{
				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}

				string oneLabel = createLabel();
				string skipLabel = createLabel();
	
				codeWrite << "\t" << "POP AX" << endl;
				codeWrite << "\t\t" << ";Line no# " << symbol->getStartLine() << ": NOT unary_expression " << endl;
				codeWrite << "\tCMP AX,0" << endl;
				codeWrite << "\tJE " << oneLabel << endl;
				codeWrite << "\tMOV AX, 0" << endl;
				codeWrite << "\tJMP " << skipLabel << endl;

				codeWrite << oneLabel << ":" << endl;
				codeWrite << "\t" << "MOV AX, 1" << endl;

				codeWrite << skipLabel << ":" << endl;
				codeWrite << "\t" << "PUSH AX" << endl;

				return;
			}

				for( auto child : symbol->getChildren())
				{
					generateCode(child);	
				}
				return;
		}



		//FACTOR

		else if(symbol->getSymbolType()=="factor")	
		{
			
			if(symbol->getSymbolName()=="ID LPAREN argument_list RPAREN")
			{
				//codeWrite<<"L"<<labelCounter++<<":\n";
				for( auto child : symbol->getChildren())
			{
				generateCode(child);	
			}
				codeWrite<<"\tCALL "<<symbol->getChildren()[0]->getSymbolName()<<endl;
				codeWrite<<"\tPUSH CX\n";
			 return;
			
			}
			
		    if(symbol->getSymbolName()=="CONST_INT" || symbol->getSymbolName()=="CONST_FLOAT")
			{
				codeWrite<<"\tMOV AX, "<<symbol->getChildren()[0]->getSymbolName()<<"\t; Line "<<symbol->getEndLine()<<endl;
				codeWrite<<"\tPUSH AX\n";
				return;
			}
			
			if(symbol->getSymbolName()=="variable INCOP")
			{
				
				string varName = symbol->getChildren()[0]->getChildren()[0]->getSymbolName();
				SymbolInfo* var = Table->lookupSymbol(varName);
				if(var->getGlobalStatus())
				{
					if(var->getArrayStatus())
					{
						generateCode(symbol->getChildren()[0]->getChildren()[2]);
						codeWrite << "\t" << "POP AX" << endl;
						codeWrite << "\t" << "LEA SI," << var->getSymbolName()<< endl;
						codeWrite << "\t" << "ADD SI, AX" << endl;
						codeWrite << "\t" << "ADD SI, AX" << endl;
						codeWrite << "\t" << "MOV AX, [SI]" << endl;
						codeWrite << "\t" << "PUSH AX" << endl;
						codeWrite << "\t" << "ADD AX, 1" << endl;
						codeWrite << "\t" << "MOV [SI], AX" << endl;
					}
					else
					{
						codeWrite << "\t" << "MOV AX, " << var->getSymbolName() << endl;
						codeWrite << "\t" << "PUSH AX" << endl;
						codeWrite << "\t" << "ADD AX,1" << endl;
						codeWrite << "\t" << "MOV "<< var->getSymbolName() << ", AX" << endl;
					
					}
				}
				else
				{
					if(var->getArrayStatus())
					{
						generateCode(symbol->getChildren()[0]->getChildren()[2]);
						codeWrite << "\tPOP BX" << endl;
						codeWrite << "\tMOV AX, 2" << endl;
						codeWrite << "\t" << "CWD" << endl;
						codeWrite << "\t" << "IMUL BX" << endl;
						codeWrite << "\tMOV BX, AX" << endl;
						codeWrite << "\tADD BX," << var->getOffset() << endl;
				
						codeWrite << "\t" << "PUSH DI" << endl;
						codeWrite << "\t" << "MOV DI, BX" << endl;	
						codeWrite << "\t" << "NEG DI" << endl;		
						codeWrite << "\t" << "MOV AX, [BP+DI]" << endl;
						codeWrite << "\t" << "MOV DX, AX" << endl;
						codeWrite << "\t" << "ADD AX, 1" << endl;
						codeWrite << "\t" << "MOV [BP+DI], AX" << endl;
						codeWrite << "\t" << "POP DI" << endl;
						codeWrite << "\t" << "PUSH DX" << endl;
					}
					else
					{
						codeWrite << "\t" << "MOV AX, [BP- " << var->getOffset() << "]" << endl;
						codeWrite << "\t" << "PUSH AX" << endl;
						codeWrite << "\t" << "ADD AX, 1" << endl;
						codeWrite << "\t" << "MOV [BP- " << var->getOffset() << "], AX" << endl;
					}
				}

				return;
			
			}
			
			if(symbol->getSymbolName()=="variable DECOP")
			{
			
				string varName = symbol->getChildren()[0]->getChildren()[0]->getSymbolName();
				SymbolInfo* var = Table->lookupSymbol(varName);
				if(var->getGlobalStatus())
				{
					if(var->getArrayStatus())
					{
						generateCode(symbol->getChildren()[0]->getChildren()[2]);
						codeWrite << "\t" << "POP AX" << endl;
						codeWrite << "\t" << "LEA SI," << var->getSymbolName()<< endl;
						codeWrite << "\t" << "ADD SI, AX" << endl;
						codeWrite << "\t" << "ADD SI, AX" << endl;
						codeWrite << "\t" << "MOV AX, [SI]" << endl;
						codeWrite << "\t" << "PUSH AX" << endl;
						codeWrite << "\t" << "SUB AX, 1" << endl;
						codeWrite << "\t" << "MOV [SI], AX" << endl;
					}
					else
					{
						codeWrite << "\t" << "MOV AX, " << var->getSymbolName() << endl;
						codeWrite << "\t" << "PUSH AX" << endl;
						codeWrite << "\t" << "SUB AX,1" << endl;
						codeWrite << "\t" << "MOV "<< var->getSymbolName() << ", AX" << endl;
					
					}
				}
				else
				{
					if(var->getArrayStatus())
					{
						generateCode(symbol->getChildren()[0]->getChildren()[2]);
						codeWrite << "\tPOP BX" << endl;
						codeWrite << "\tMOV AX, 2" << endl;
						codeWrite << "\t" << "CWD" << endl;
						codeWrite << "\t" << "IMUL BX" << endl;
						codeWrite << "\tMOV BX, AX" << endl;
						codeWrite << "\tADD BX," << var->getOffset() << endl;
				
						codeWrite << "\t" << "PUSH DI" << endl;
						codeWrite << "\t" << "MOV DI, BX" << endl;	
						codeWrite << "\t" << "NEG DI" << endl;		
						codeWrite << "\t" << "MOV AX, [BP+DI]" << endl;
						codeWrite << "\t" << "MOV DX, AX" << endl;
						codeWrite << "\t" << "SUB AX, 1" << endl;
						codeWrite << "\t" << "MOV [BP+DI], AX" << endl;
						codeWrite << "\t" << "POP DI" << endl;
						codeWrite << "\t" << "PUSH DX" << endl;
					}
					else
					{
						codeWrite << "\t" << "MOV AX, [BP- " << var->getOffset() << "]" << endl;
						codeWrite << "\t" << "PUSH AX" << endl;
						codeWrite << "\t" << "SUB AX, 1" << endl;
						codeWrite << "\t" << "MOV [BP- " << var->getOffset() << "], AX" << endl;
					}
				}

				return;
			
			}

			for( auto child : symbol->getChildren())
			{
				generateCode(child);	
			}
			return;
		}


		//ARGUMENTS

		else if(symbol->getSymbolType()=="arguments")
		{
			if(symbol->getSymbolName()=="arguments COMMA logic_expression")
			{
				generateCode(symbol->getChildren()[2]);
				generateCode(symbol->getChildren()[0]);
			}
			if(symbol->getSymbolName()=="logic_expression")
			{
				generateCode(symbol->getChildren()[0]);
			}
		}

		else
		{
			for( auto child : symbol->getChildren())
			{

			generateCode(child);
			
			}
		}
		
		
	}
	
}


%}
%union {
	SymbolInfo *symbolInfo;
}

%token<symbolInfo> IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE CONST_INT CONST_FLOAT CONST_CHAR ID NOT LOGICOP RELOP ADDOP MULOP INCOP DECOP ASSIGNOP LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON BITOP SINGLE_LINE_STRING MULTI_LINE_STRING LOWER_THAN_ELSE PRINTLN 
%type<symbolInfo> start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments 

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

		
		start = $$;
		
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
					symbol->setArraySize(var->getArraySize());
					if(Table->getCurScopeTable()->getID()=="1")
					{
						symbol->setGlobalStatus(true);
					}
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
					else if(Table->getCurScopeTable()->getID()=="1")
					{
						globalVars.push_back(symbol);
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
			$$ = new SymbolInfo("declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", "declaration_list");
			$3->setArrayStatus(true);
			$3->setArraySize(stoi($5->getSymbolName()));
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
			$$ = new SymbolInfo("ID LTHIRD CONST_INT RTHIRD", "declaration_list");		
			$1->setArrayStatus(true);
			$1->setArraySize(stoi($3->getSymbolName()));	
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
			$$ = new SymbolInfo("ID LTHIRD expression RTHIRD", "variable");
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

	logWrite.open("2005117_log.txt");
	errorWrite.open("2005117_error.txt");
	ptWrite.open("2005117_parsetree.txt");
	codeWrite.open("2005117_code.asm");
	optWrite.open("2005117_optcode.asm");
	
	yyin=fp;
	yyparse();

	printParseTree(start,0);
	generateCode(start);
	Optimize();
	
	fclose(yyin);
	logWrite.close();
	errorWrite.close();
	ptWrite.close();
	codeWrite.close();
	optWrite.close();
	
	return 0;
}

