#ifndef SYMBOLINFO_H
#define SYMBOLINFO_H

#include <bits/stdc++.h>
using namespace std;

class SymbolInfo
{
private:
    string symbolName;
    string symbolType;
    int startLine;
    int endLine;
    int offset;
    int arraySize;
    bool leafStatus = false;
    bool arrayStatus = false;
    bool functionStatus = false;
    bool zeroStatus = false; 
    bool globalStatus = false;
    string type_specifier;
    vector <SymbolInfo*> children;
    SymbolInfo *nextSymbol;
    vector<SymbolInfo*> paramList;
    vector<SymbolInfo*> declarationList;
    

public:
   
  
SymbolInfo(){}

SymbolInfo(const string& name, const string& type):symbolName(name),symbolType(type)
{
    nextSymbol = nullptr;
}

~SymbolInfo()
{
    children.clear();
}


string getSymbolName()
{
    return this->symbolName;
}

string getSymbolType()
{
    return this->symbolType;
}

SymbolInfo* getNextSymbol()
{
    return this->nextSymbol;
}

void setNextSymbol(SymbolInfo *symbol)
{
    this->nextSymbol = symbol;
}
void setGlobalStatus(bool flag)
{
    this->globalStatus = flag;
}
bool getGlobalStatus()
{
    return this->globalStatus;
}
void setOffset(int offset)
{
    this->offset = offset;
}
int getOffset()
{
    return this->offset;
}
void setArraySize(int size)
{
    this->arraySize = size;
}
int getArraySize()
{
    return this->arraySize;
}
void setStartLine(int lineCount)
{
    this->startLine = lineCount;
}

int getStartLine()
{
    return this->startLine;
}

void setEndLine(int lineCount)
{
    this->endLine = lineCount;
}

int getEndLine()
{
    return this->endLine;
}

void setLeafStatus(bool flag)
{
    this->leafStatus = flag;
}

bool getLeafStatus()
{
    return this->leafStatus;
}

void setParseTreeInfos(int sline, int eline, bool lflag)
{
    this->startLine = sline;
    this->endLine = eline;
    this->leafStatus = lflag;
}

void setFunctionStatus(bool flag)
{
    this->functionStatus = flag;
}

bool getFunctionStatus()
{
    return this->functionStatus;
}

void addChild(SymbolInfo* symbol)
{
    children.push_back(symbol);
}

void setTypeSpecifier (string type_specifier)
{
    this->type_specifier = type_specifier;
}

string getTypeSpecifier()
{
    return this->type_specifier;
}

  bool getZeroStatus()
    {
        return this->zeroStatus;
    }
    void setZeroStatus(bool flag)
    {
        this->zeroStatus = flag;
    }
    void setArrayStatus(bool flag)
    {
        this->arrayStatus = flag;
    }
    bool getArrayStatus()
    {
        return arrayStatus;
    }
    void addToDeclaration(SymbolInfo *symbol)
    {
        declarationList.push_back(symbol);
    }
    
    void setDeclarationList(vector<SymbolInfo*> &list)
    {
        this->declarationList = list;
    }

    vector<SymbolInfo*> &getDeclarationList()
    {
        return declarationList;
    }
    vector <SymbolInfo*> &getChildren()
    { 
        return children;
    }

    void addToParameterList(SymbolInfo* param)
    {
        paramList.push_back(param);
    }
    void setParameterList(vector<SymbolInfo*> &list)
    {
        this->paramList = list;
    }
    vector <SymbolInfo*> &getParameterList()
    { 
        return paramList;
    }
    void clearParameterList()
    {
        paramList.clear();
    }

};





#endif