#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H




#include <bits/stdc++.h>
#include "2005117_ScopeTable.h"

using namespace std;


class SymbolTable
{
private:
    int total_buckets;
    ScopeTable *curScopeTable;
    int scopeCount;
public:
   
SymbolTable(int Size) : total_buckets(Size)
{
    curScopeTable = new ScopeTable(Size,"1");
    scopeCount = 1;
}

~SymbolTable()
{
    while(curScopeTable!=nullptr)
    {
        ScopeTable* temp = curScopeTable->getParentScope();
        //cout<<"\tScopeTable# "<<curScopeTable->getID()<<" deleted"<<endl;
        delete curScopeTable;
        curScopeTable = temp;
    }
}

void enterScope()
{
    if(curScopeTable==nullptr)
    {
        return;
    }
    scopeCount++;
    int curr_id = scopeCount;
    string newId = to_string(curr_id);
    ScopeTable *newScope = new ScopeTable(total_buckets,newId);
    newScope->setParentScope(curScopeTable);
    curScopeTable->setChildCount(curr_id);
    curScopeTable = newScope;
}

void exitScope()
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

bool insertSymbol(SymbolInfo *symbol)
{
     if(curScopeTable==nullptr)
    {
        return false;
    }
    // if(this->lookupSymbol(symbol->getSymbolName())!=nullptr)
    // {
    //     return false;
    // }
    bool success = curScopeTable->insertSymbol(symbol);
    return success;
}

bool removeSymbol(string symbolName)
{
     if(curScopeTable==nullptr)
    {
        return false;
    }
    bool success = curScopeTable->deleteSymbol(symbolName);
    return success;
}

SymbolInfo* lookupSymbol(string symbolName)
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

void printCur(ofstream &ofile)
{
    curScopeTable->printTable(ofile);
}

void printAll(ofstream &ofile)
{
    ScopeTable *curr = curScopeTable;
    while(curr!=nullptr)
    {
        curr->printTable(ofile);
        curr = curr->getParentScope();
    }
}

};

#endif