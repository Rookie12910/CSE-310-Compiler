%option noyywrap

%x STRING_STATE
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT

%{

 #include<stdio.h>
 #include<stdlib.h>
 #include <string.h>
 #include <ctype.h> 
 #include "2005117_SymbolTable.h"   
 #define total_buckets 10

 int lineCount = 1;
 int startingLineCount; //Needed in case of multi line string and comment
 int errorCount = 0;
 int warningCount = 0;

 bool indCheckFlag = false;
 int reqtabCount = 0;
 int curtabCount = 0;
 int curSpaceCount = 0;

 FILE *logWrite;
 FILE *tokenWrite;


 string stringLog;
 string stringToken;
 int stringLineCount;
 string commentString;


SymbolTable *symbolTable = new SymbolTable(total_buckets);

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

void indentationCheck(){
     if(indCheckFlag){
        indCheckFlag = false;
        if(curtabCount+(curSpaceCount*1.0)/4!=reqtabCount){
            if(curSpaceCount>0)
            {
            fprintf(logWrite,"Line# %d: Warning, tab requrired but got space.\n",lineCount);
            warningCount++;
            }
            else{
            fprintf(logWrite,"Line# %d: warning, %d of tabs needed but got %d tabs.\n",lineCount,reqtabCount,curtabCount);
            warningCount++;
            }
           
        }
    }
}



%}

NEWLINE \n
KEYWORD (if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue)
DIGIT [0-9]
CONST_INT {DIGIT}+
CONST_FLOAT {DIGIT}*(\.{DIGIT}+)?({DIGIT}+[Ee][+-]?{DIGIT}+)? 
CONST_CHAR '([^'\n])'|'(\\[ntafrbv0?\\\'\"])'
IDENTIFIER [A-Za-z_][A-Za-z0-9_]*
WHITESPACE [\r\v\f]
ADDOP [+-]
MULOP [*/%]
INCOP ("++"|"--")
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
    indCheckFlag = true;
    curtabCount = 0;
    curSpaceCount = 0;
    lineCount++;
}

{WHITESPACE}+ {}

" " {
    if(indCheckFlag) curSpaceCount++;
}

"\t" {
    if(indCheckFlag) curtabCount++;
}

{KEYWORD} {
    indentationCheck();
    char *Token = getUpperCaseToken(yytext);
    fprintf(tokenWrite,"<%s, %s>\n",Token,yytext);
	fprintf(logWrite,"Line# %d: Token <%s> Lexeme %s found\n",lineCount,Token,yytext);
    free(Token);
}

{CONST_INT} {
    indentationCheck();
    fprintf(tokenWrite,"<CONST_INT, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <CONST_INT> Lexeme %s found\n",lineCount,yytext);
}

{CONST_FLOAT} {
    indentationCheck();
    fprintf(tokenWrite,"<CONST_FLOAT, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",lineCount,yytext);
}

(({DIGIT}*\.{DIGIT}*)+\.{DIGIT}*([Ee][+-]?{DIGIT}+)?) {
    indentationCheck();
    errorCount++;
    fprintf(logWrite,"Error at line# %d: TOO_MANY_DECIMAL_POINTS %s\n",lineCount,yytext);
}

({DIGIT}+\.)|({DIGIT}*([Ee][+-]?{DIGIT}*)+(\.{DIGIT}*)+) {
    indentationCheck();
    errorCount++;
    fprintf(logWrite,"Error at line# %d: ILLFORMED_NUMBER %s\n",lineCount,yytext);
}

'\\'|('[^'\n])|' {
    indentationCheck();
    errorCount++;
    fprintf(logWrite,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",lineCount,yytext);
}

'' {
    indentationCheck();
    errorCount++;
    fprintf(logWrite,"Error at line# %d: EMPTY_CONST_CHAR %s\n",lineCount,yytext);
}

{CONST_CHAR} {
    indentationCheck();
    fprintf(tokenWrite,"<CONST_CHAR, %c>\n",getActualCharacter(yytext));
	fprintf(logWrite,"Line# %d: Token <CONST_CHAR> Lexeme %c found\n",lineCount,getActualCharacter(yytext));
}

'([^'\n])([^'\n])+' {
    indentationCheck();
    errorCount++;
    fprintf(logWrite,"Error at line# %d: MULTICHAR_CONST_CHAR %s\n",lineCount,yytext);
}




{ADDOP} {
    indentationCheck();
    fprintf(tokenWrite,"<ADDOP, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <ADDOP> Lexeme %s found\n",lineCount,yytext);
}


{MULOP} {
    indentationCheck();
    fprintf(tokenWrite,"<MULOP, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <MULOP> Lexeme %s found\n",lineCount,yytext);
}

{INCOP} {
    indentationCheck();
    fprintf(tokenWrite,"<INCOP, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <INCOP> Lexeme %s found\n",lineCount,yytext);
}

{RELOP} {
    indentationCheck();
    fprintf(tokenWrite,"<RELOP, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <RELOP> Lexeme %s found\n",lineCount,yytext);
}

{ASSIGNOP} {
    indentationCheck();
    fprintf(tokenWrite,"<ASSIGNOP, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",lineCount,yytext);
}

{LOGICOP} {
    indentationCheck();
    fprintf(tokenWrite,"<LOGICOP, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <LOGICOP> Lexeme %s found\n",lineCount,yytext);
}

{BITOP} {
    indentationCheck();
    fprintf(tokenWrite,"<BITOP, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <BITOP> Lexeme %s found\n",lineCount,yytext);
}

{NOT} {
    indentationCheck();
    fprintf(tokenWrite,"<NOT, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <NOT> Lexeme %s found\n",lineCount,yytext);
}

{LPAREN} {
    indentationCheck();
    fprintf(tokenWrite,"<LPAREN, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <LPAREN> Lexeme %s found\n",lineCount,yytext);
}

{RPAREN} {
    indentationCheck();
    fprintf(tokenWrite,"<RPAREN, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <RPAREN> Lexeme %s found\n",lineCount,yytext);
}  

{LCURL} {
    indentationCheck();
    reqtabCount++;
    symbolTable->enterScope();
    fprintf(tokenWrite,"<LCURL, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <LCURL> Lexeme %s found\n",lineCount,yytext);
}

{RCURL} {
    reqtabCount--;
    indentationCheck();
    symbolTable->exitScope();
    fprintf(tokenWrite,"<RCURL, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <RCURL> Lexeme %s found\n",lineCount,yytext);
}

{LSQUARE} {
    indentationCheck();
    fprintf(tokenWrite,"<LSQUARE, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <LSQUARE> Lexeme %s found\n",lineCount,yytext);
}

{RSQUARE} {
    indentationCheck();
    fprintf(tokenWrite,"<RSQUARE, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <RSQUARE> Lexeme %s found\n",lineCount,yytext);
}

{COMMA} {
    indentationCheck();
    fprintf(tokenWrite,"<COMMA, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <COMMA> Lexeme %s found\n",lineCount,yytext);
}

{SEMICOLON} {
    indentationCheck();
    fprintf(tokenWrite,"<SEMICOLON, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",lineCount,yytext);
}

{IDENTIFIER} {
    indentationCheck();
    fprintf(tokenWrite,"<ID, %s>\n",yytext);
	fprintf(logWrite,"Line# %d: Token <ID> Lexeme %s found\n",lineCount,yytext);
    SymbolInfo *symbol = new SymbolInfo(yytext,"ID");
    bool success = symbolTable->insertSymbol(symbol);
    if(success) {
        symbolTable->printAll(logWrite);
    } 
    else {
        fprintf(logWrite,"\t%s already exists in the current ScopeTable\n",yytext);
    }
}

({DIGIT}+[A-Za-z_]+)|([A-Za-z_]+{DIGIT}+) {
    indentationCheck();
    errorCount++;
    fprintf(logWrite,"Error at line# %d: INVALID_ID_SUFFIX_NUM_PREFIX %s\n",lineCount,yytext);
}


\" {
    indentationCheck();
    stringLog = "";
    stringToken = "";
    startingLineCount = lineCount;
    BEGIN STRING_STATE;
    stringLog.append(yytext);
    stringLineCount = 1;
}

<STRING_STATE>\" {
    stringLog.append(yytext);
    if(stringLineCount==1){
        fprintf(tokenWrite,"<SINGLE LINE STRING, %s>\n",stringToken.c_str());
	    fprintf(logWrite,"Line# %d: Token <SINGLE LINE STRING> Lexeme %s found\n",startingLineCount,stringLog.c_str());
    }
    else if(stringLineCount>1){
        fprintf(tokenWrite,"<MULTI LINE STRING, %s>\n",stringToken.c_str());
	    fprintf(logWrite,"Line# %d: Token <MULTI LINE STRING> Lexeme %s found\n",startingLineCount,stringLog.c_str());
    }
    BEGIN INITIAL;
}

<STRING_STATE>. {
    stringLog.append(yytext);
    stringToken.append(yytext);
}

<STRING_STATE>\\{NEWLINE} {
    stringLog.append(yytext);
    stringLineCount++;
    lineCount++;
}



<STRING_STATE>(\\[ntafrbv0\\\'\"]) {
    stringLog.append(yytext);
    switch (yytext[1]) {
            case 'n':
                stringToken.append("\n");
                break;
            case 't':
                stringToken.append("\t");
                break;
            case '\\':
                stringToken.append("\\");
                break;
            case '\'':
                stringToken.append("\'");
                break;
            case 'a':
               stringToken.append("\a");
               break;
            case 'f':
                stringToken.append("\f");
                break;
            case 'r':
                stringToken.append("\r");
                break;
            case 'b':
                stringToken.append("\b");
                break;
            case 'v':
                stringToken.append("\v");
                break;
            case '0':
                stringToken.append("\0");
                break;
            case '\"':
                stringToken.append("\"");
                break;
            default:
                stringToken.append(yytext);
                
}
}


<STRING_STATE>{NEWLINE} {
    indCheckFlag = true;
    curtabCount = 0;
    curSpaceCount = 0;
    errorCount++;
    fprintf(logWrite,"Error at line# %d: UNFINISHED_STRING %s\n",lineCount,stringLog.c_str());
    lineCount++;
    BEGIN INITIAL;
}

<STRING_STATE><<EOF>> {
    errorCount++;
    fprintf(logWrite,"Error at line# %d: UNFINISHED_STRING %s\n",lineCount,stringLog.c_str());
    BEGIN INITIAL;
}

\/\/ {
    indentationCheck();
    BEGIN SINGLE_LINE_COMMENT;
    commentString = "";
    startingLineCount = lineCount;
    commentString.append(yytext);
}

<SINGLE_LINE_COMMENT>\\{NEWLINE} {
    commentString.append(yytext);
    lineCount++;
}

<SINGLE_LINE_COMMENT>{NEWLINE} {
    indCheckFlag = true;
    curtabCount = 0;
    curSpaceCount = 0;
    fprintf(logWrite,"Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s found\n",startingLineCount,commentString.c_str());
    lineCount++;
    BEGIN INITIAL;
}


<SINGLE_LINE_COMMENT>. {
    commentString.append(yytext);
}


\/\* {
    indentationCheck();
    BEGIN MULTI_LINE_COMMENT;
    commentString = "";
    startingLineCount = lineCount;
    commentString.append(yytext);
}

<MULTI_LINE_COMMENT>{NEWLINE} {
    commentString.append(yytext);
    lineCount++;
}

<MULTI_LINE_COMMENT>\*\/ {
    commentString.append(yytext);
    fprintf(logWrite,"Line# %d: Token <MULTI LINE COMMENT> Lexeme %s found\n",startingLineCount,commentString.c_str());
    BEGIN INITIAL;
}



<MULTI_LINE_COMMENT>. {
    indentationCheck();
    commentString.append(yytext);
}

<MULTI_LINE_COMMENT><<EOF>> {
    errorCount++;
    fprintf(logWrite,"Error at line# %d: UNFINISHED_COMMENT %s\n",lineCount,commentString.c_str());
    BEGIN INITIAL;
}

[^a-zA-Z0-9] {
    indentationCheck();
    errorCount++;
    fprintf(logWrite,"Error at line# %d: UNRECOGNIZED_CHAR %s\n",lineCount,yytext);
}

<<EOF>> {
    symbolTable->printAll(logWrite);
    fprintf(logWrite,"Total lines: %d\n",lineCount);
    fprintf(logWrite,"Total errors: %d\n",errorCount);
    fprintf(logWrite,"Total warnings: %d\n",warningCount);
    return 0;
}

%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
    logWrite= fopen("2005117_log.txt","w");
	tokenWrite= fopen("2005117_token.txt","w");

	yyin= fin;
	yylex();
	fclose(yyin);
    fclose(logWrite);
    fclose(tokenWrite);
	return 0;
}