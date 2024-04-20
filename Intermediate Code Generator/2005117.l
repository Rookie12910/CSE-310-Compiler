%option noyywrap

%{

 #include<stdio.h>
 #include<stdlib.h>
 #include <string.h>
 #include <ctype.h> 
 #include "2005117_SymbolTable.h"   
 #include "y.tab.h"

 using namespace std;

 void yyerror(char *);

 int lineCount = 1;
 int startingLineCount = 0; 
 int errorCount = 0;

 
 extern ofstream logWrite;
 extern ofstream errorWrite;
 extern SymbolTable *Table;
 extern SymbolInfo scopeParam;


 char* getUpperCaseToken(const char *s) {
    char *result = (char*)malloc(strlen(s) + 1); 
    if (result == NULL) {
        return NULL;
    }
    strcpy(result, s); 
    for (int i = 0; result[i] != '\0'; i++) {
        result[i] = toupper((unsigned char)result[i]);
    }

    return result;
}

char getActualCharacter(char *ch) {
    if (ch[1] == '\\') {
        switch (ch[2]) {
            case 'n':
                return '\n';
            case 't':
                return '\t';
            case '\\':
                return '\\';
            case '\'':
                return '\'';
            case 'a':
                return '\a';
            case 'f':
                return '\f';
            case 'r':
                return '\r';
            case 'b':
                return '\b';
            case 'v':
                return '\v';
            case '0':
                return '\0';
            case '?':
                return '\?';
            case '\"':
                return '\"';
            default:
                return *ch;
        }
    }
    return ch[1];
}

// void indentationCheck(){
//      if(indCheckFlag){
//         indCheckFlag = false;
//         if(curtabCount+(curSpaceCount*1.0)/4!=reqtabCount){
//             if(curSpaceCount>0)
//             {
//             fprintf(logWrite,"Line# %d: Warning, tab requrired but got space.\n",lineCount);
//             warningCount++;
//             }
//             else{
//             fprintf(logWrite,"Line# %d: warning, %d of tabs needed but got %d tabs.\n",lineCount,reqtabCount,curtabCount);
//             warningCount++;
//             }
           
//         }
//     }
// }



%}

NEWLINE \n
DIGIT [0-9]
CONST_INT {DIGIT}+
CONST_FLOAT {DIGIT}*(\.{DIGIT}+)?({DIGIT}+[Ee][+-]?{DIGIT}+)? 
CONST_CHAR '([^'\n])'|'(\\[ntafrbv0?\\\'\"])'
IDENTIFIER [A-Za-z_][A-Za-z0-9_]*
WHITESPACE [ \t\r\v\f]
ADDOP [+-]
MULOP [*/%]
INCOP ("++")
DECOP ("--")
RELOP ("<"|"<="|">"|">="|"=="|"!=")
ASSIGNOP [=]
LOGICOP ("&&"|"||")
BITOP ("&"|"|"|"^"|"<<"|">>")
NOT [!]
LPAREN [(]
RPAREN [)]
LCURL [{]
RCURL [}]
LSQUARE ("[")
RSQUARE ("]")
COMMA [,]
SEMICOLON [;]



%%

{NEWLINE} {
    lineCount++;
}

{WHITESPACE}+ {}


"if" {
    yylval.symbolInfo = new SymbolInfo(yytext,"IF");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return IF;
}

"else" {
    yylval.symbolInfo = new SymbolInfo(yytext,"ELSE");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return ELSE;
}

"for" {
    yylval.symbolInfo = new SymbolInfo(yytext,"FOR");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return FOR;
}
"while" {
    yylval.symbolInfo = new SymbolInfo(yytext,"WHILE");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return WHILE;
}

"do" {
    yylval.symbolInfo = new SymbolInfo(yytext,"DO");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return DO;
}

"break" {
    yylval.symbolInfo = new SymbolInfo(yytext,"BREAK");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return BREAK;
}

"int" {
    yylval.symbolInfo = new SymbolInfo(yytext,"INT");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return INT;
}

"char" {
    yylval.symbolInfo = new SymbolInfo(yytext,"CHAR");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return CHAR;
}

"double" {
    yylval.symbolInfo = new SymbolInfo(yytext,"DOUBLE");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return DOUBLE;
}

"float" {
    yylval.symbolInfo = new SymbolInfo(yytext,"FLOAT");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return FLOAT;
}

"return" {
    yylval.symbolInfo = new SymbolInfo(yytext,"RETURN");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return RETURN;
}

"switch" {
    yylval.symbolInfo = new SymbolInfo(yytext,"SWITCH");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return SWITCH;
}

"case" {
    yylval.symbolInfo = new SymbolInfo(yytext,"CASE");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return CASE;
}

"default" {
    yylval.symbolInfo = new SymbolInfo(yytext,"DEFAULT");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return DEFAULT;
}

"continue" {
    yylval.symbolInfo = new SymbolInfo(yytext,"CONTINUE");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return CONTINUE;
}

"println" {
    yylval.symbolInfo = new SymbolInfo(yytext,"PRINTLN");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return PRINTLN;
}

"void" {
    yylval.symbolInfo = new SymbolInfo(yytext,"VOID");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <"<<getUpperCaseToken(yytext)<<"> Lexeme "<<yytext<<" found"<<endl;
    return VOID;
}


{CONST_INT} {
    yylval.symbolInfo = new SymbolInfo(yytext,"CONST_INT");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <CONST_INT> Lexeme "<<yytext<<" found"<<endl;
    return CONST_INT;
}

{CONST_FLOAT} {
    yylval.symbolInfo = new SymbolInfo(yytext,"CONST_FLOAT");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <CONST_FLOAT> Lexeme "<<yytext<<" found"<<endl;
    return CONST_FLOAT;
}

(({DIGIT}*\.{DIGIT}*)+\.{DIGIT}*([Ee][+-]?{DIGIT}+)?) {
    errorCount++;
    logWrite<<"Line# "<<lineCount<<": TOO_MANY_DECIMAL_POINTS."<<endl;
}

({DIGIT}+\.)|({DIGIT}*([Ee][+-]?{DIGIT}*)+(\.{DIGIT}*)+) {
    errorCount++;
    logWrite<<"Line# "<<lineCount<<": ILLFORMED_NUMBER."<<endl;
}

'\\'|('[^'\n])|' {
    errorCount++;
    logWrite<<"Line# "<<lineCount<<": UNFINISHED_CONST_CHAR."<<endl;
}

'' {
    errorCount++;
    logWrite<<"Line# "<<lineCount<<": EMPTY_CONST_CHAR."<<endl;
}

{CONST_CHAR} {
    yylval.symbolInfo = new SymbolInfo(yytext,"CONST_CHAR");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <CONST_CHAR> Lexeme "<<yytext<<" found"<<endl;
    return CONST_CHAR;
}

'([^'\n])([^'\n])+' {
    errorCount++;
    logWrite<<"Line# "<<lineCount<<": MULTICHAR_CONST_CHAR."<<endl;
}




{ADDOP} {
    yylval.symbolInfo = new SymbolInfo(yytext,"ADDOP");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <ADDOP> Lexeme "<<yytext<<" found"<<endl;
    return ADDOP;
}


{MULOP} {
    yylval.symbolInfo = new SymbolInfo(yytext,"MULOP");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <MULOP> Lexeme "<<yytext<<" found"<<endl;
    return MULOP;
}

{INCOP} {
    yylval.symbolInfo = new SymbolInfo(yytext,"INCOP");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <INCOP> Lexeme "<<yytext<<" found"<<endl;
    return INCOP;
}
{DECOP} {
    yylval.symbolInfo = new SymbolInfo(yytext,"DECOP");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <DECOP> Lexeme "<<yytext<<" found"<<endl;
    return DECOP;
}
{RELOP} {
    yylval.symbolInfo = new SymbolInfo(yytext,"RELOP");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <RELOP> Lexeme "<<yytext<<" found"<<endl;
    return RELOP;
}

{ASSIGNOP} {
    yylval.symbolInfo = new SymbolInfo(yytext,"ASSIGNOP");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <ASSIGNOP> Lexeme "<<yytext<<" found"<<endl;
    return ASSIGNOP;
}

{LOGICOP} {
    yylval.symbolInfo = new SymbolInfo(yytext,"LOGICOP");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <LOGICOP> Lexeme "<<yytext<<" found"<<endl;
    return LOGICOP;
}

{BITOP} {
    yylval.symbolInfo = new SymbolInfo(yytext,"BITOP");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <BITOP> Lexeme "<<yytext<<" found"<<endl;
    return BITOP;
}

{NOT} {
    yylval.symbolInfo = new SymbolInfo(yytext,"NOT");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <NOT> Lexeme "<<yytext<<" found"<<endl;
    return NOT;
}

{LPAREN} {
    yylval.symbolInfo = new SymbolInfo(yytext,"LPAREN");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <LPAREN> Lexeme "<<yytext<<" found"<<endl;
    return LPAREN;
}

{RPAREN} {
    yylval.symbolInfo = new SymbolInfo(yytext,"RPAREN");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <RPAREN> Lexeme "<<yytext<<" found"<<endl;
    return RPAREN;
}  

{LCURL} {
    yylval.symbolInfo = new SymbolInfo(yytext,"LCURL");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    Table->enterScope();
    for(auto var : scopeParam.getParameterList())
    {
                SymbolInfo *symbol = new SymbolInfo(var->getSymbolName(),var->getSymbolType());
				symbol->setTypeSpecifier(var->getTypeSpecifier());
				bool success = Table->insertSymbol(symbol);
				if(!success)
				{

				}
    }
    logWrite<<"Line# "<<lineCount<<": Token <LCURL> Lexeme "<<yytext<<" found"<<endl;
    return LCURL;
}

"}" {
    yylval.symbolInfo = new SymbolInfo(yytext,"RCURL");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    scopeParam.clearParameterList();
    logWrite<<"Line# "<<lineCount<<": Token <RCURL> Lexeme "<<yytext<<" found"<<endl;
    return RCURL;
}

{LSQUARE} {
    yylval.symbolInfo = new SymbolInfo(yytext,"LSQUARE");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <LSQUARE> Lexeme "<<yytext<<" found"<<endl;
    return LTHIRD;
}

{RSQUARE} {
    yylval.symbolInfo = new SymbolInfo(yytext,"RSQUARE");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <RSQUARE> Lexeme "<<yytext<<" found"<<endl;
    return RTHIRD;
}

{COMMA} {
    yylval.symbolInfo = new SymbolInfo(yytext,"COMMA");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <COMMA> Lexeme "<<yytext<<" found"<<endl;
    return COMMA;
}

{SEMICOLON} {
    yylval.symbolInfo = new SymbolInfo(yytext,"SEMICOLON");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <SEMICOLON> Lexeme "<<yytext<<" found"<<endl;
    return SEMICOLON;
}

{IDENTIFIER} {
    yylval.symbolInfo = new SymbolInfo(yytext,"ID");
    yylval.symbolInfo->setParseTreeInfos(lineCount,lineCount,true);
    logWrite<<"Line# "<<lineCount<<": Token <ID> Lexeme "<<yytext<<" found"<<endl;
    return ID;
}

({DIGIT}+[A-Za-z_]+)|([A-Za-z_]+{DIGIT}+) {
    
    errorCount++;
    logWrite<<"Line# "<<lineCount<<": INVALID_ID_SUFFIX_NUM_PREFIX."<<endl;
}

[^a-zA-Z0-9] {
    errorCount++;
    logWrite<<"Line# "<<lineCount<<": UNRECOGNIZED_CHAR."<<endl;
}

%%
