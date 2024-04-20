#include "2005117_ScopeTable.h"
//#include<bits/stdc++.h>

using namespace std;

class SymbolTable
{
private:
    int total_buckets;
    ScopeTable *curScopeTable;
public:
    SymbolTable(int Size);
    ~SymbolTable();
    void enterScope();
    void exitScope();
    bool insertSymbol(SymbolInfo *symbol);
    bool removeSymbol(string symbolName);
    SymbolInfo* lookupSymbol(string symbolName);
    void printCur(FILE *ofile);
    void printAll(FILE *ofile);
};

SymbolTable::SymbolTable(int Size) : total_buckets(Size)
{
    curScopeTable = new ScopeTable(Size,"1");
}

SymbolTable::~SymbolTable()
{
    while(curScopeTable!=nullptr)
    {
        ScopeTable* temp = curScopeTable->getParentScope();
        //cout<<"\tScopeTable# "<<curScopeTable->getID()<<" deleted"<<endl;
        delete curScopeTable;
        curScopeTable = temp;
    }
}

void SymbolTable::enterScope()
{
    if(curScopeTable==nullptr)
    {
        return;
    }
    int curr_id = curScopeTable->getChildCount()+1 ;
    string newId = curScopeTable->getID()+"."+to_string(curr_id);
    ScopeTable *newScope = new ScopeTable(total_buckets,newId);
    newScope->setParentScope(curScopeTable);
    curScopeTable->setChildCount(curr_id);
    curScopeTable = newScope;
}

void SymbolTable::exitScope()
{
    if(curScopeTable==nullptr)
    {
        return;
    }
    if(curScopeTable->getID()=="1")
    {
        //cout<<"\tScopeTable# "<<curScopeTable->getID()<<" cannot be deleted"<<endl;
        return;
    }
    ScopeTable *curr = curScopeTable;
    curScopeTable = curr->getParentScope();
    //cout<<"\tScopeTable# "<<curr->getID()<<" deleted"<<endl;
    delete curr;
}

bool SymbolTable::insertSymbol(SymbolInfo *symbol)
{
     if(curScopeTable==nullptr)
    {
        return false;
    }
    bool success = curScopeTable->insertSymbol(symbol);
    return success;
}

bool SymbolTable::removeSymbol(string symbolName)
{
     if(curScopeTable==nullptr)
    {
        return false;
    }
    bool success = curScopeTable->deleteSymbol(symbolName);
    return success;
}

SymbolInfo* SymbolTable::lookupSymbol(string symbolName)
{
    ScopeTable *curr = curScopeTable;
    while(curr!=nullptr)
    {
        SymbolInfo *symbol = curr->lookupSymbol(symbolName);
        if(symbol!=nullptr)
        {
            return symbol;
        }
        curr = curr->getParentScope();
    }
    //cout<<"\t'"<<symbolName<<"' not found in any of the ScopeTables"<<endl;
    return nullptr;
}

void SymbolTable::printCur(FILE *ofile)
{
    curScopeTable->printTable(ofile);
}

void SymbolTable::printAll(FILE *ofile)
{
    ScopeTable *curr = curScopeTable;
    while(curr!=nullptr)
    {
        curr->printTable(ofile);
        curr = curr->getParentScope();
    }
}
