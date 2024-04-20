#include "2005117_SymbolInfo.h"

using namespace std;

class ScopeTable
{
private:
    string ID;
    int total_buckets;
    SymbolInfo **hashTable;
    int childCount;
    ScopeTable *parentScope;

public:
    ScopeTable(int Size, string id);
    ~ScopeTable();
    unsigned int getHashvalue(string symbolName);
    bool insertSymbol(SymbolInfo* symbol);
    SymbolInfo* lookupSymbol(string symbolName);
    bool deleteSymbol(string symbolName);
    void printTable(FILE *ofile);

    int getTotalBuckets();
    string getID();
    void setID(string ID);
    ScopeTable *getParentScope();
    void setParentScope(ScopeTable* parentScope);
    int getChildCount();
    void setChildCount(int childCount);

};

ScopeTable::ScopeTable(int Size,string id) : total_buckets(Size), ID(id)
{
    hashTable = new SymbolInfo*[total_buckets];
    for(int i = 0; i<total_buckets; i++)
    {
        this->hashTable[i] = nullptr;
    }
    childCount = 0;
    parentScope = nullptr;
   // cout<<"\tScopeTable# "<<ID<<" created"<<endl;
}

ScopeTable::~ScopeTable()
{
    for(int i = 0; i<this->getTotalBuckets(); i++)
    {
        delete hashTable[i];
    }
    delete [] hashTable;
}

unsigned int ScopeTable::getHashvalue(string symbolName)
{
    unsigned long long hashval = 0;
    for(char ch:symbolName)
    {
        int c = ch;
        hashval = c + (hashval << 6) + (hashval << 16) - hashval;
    }
    hashval = hashval%this->getTotalBuckets();
    return hashval;
}


bool ScopeTable::insertSymbol(SymbolInfo* symbol)
{
    unsigned int index = this->getHashvalue(symbol->getSymbolName());
    int probeCount = 0;
    if(hashTable[index]==nullptr)
    {
        hashTable[index] = symbol;
    }

    else if(hashTable[index]->getSymbolName()==symbol->getSymbolName())
    {
        //cout<<"\t'"<<symbol->getSymbolName()<<"' already exists in the current ScopeTable# "<<this->getID()<<endl;
        return false;
    }
    else
    {
        probeCount++;
        SymbolInfo* curr = hashTable[index];
        while(curr->getNextSymbol()!=nullptr)
        {
            if(curr->getSymbolName()==symbol->getSymbolName())
            {
                //cout<<"\t'"<<symbol->getSymbolName()<<"' already exists in the current ScopeTable# "<<this->getID()<<endl;
                return false;
            }
            curr = curr->getNextSymbol();
            probeCount++;
        }
        if(curr->getSymbolName()==symbol->getSymbolName())
            {
                //cout<<"\t'"<<symbol->getSymbolName()<<"' already exists in the current ScopeTable# "<<this->getID()<<endl;
                return false;
            }
        curr->setNextSymbol(symbol);
    }
    //cout<<"\tInserted  at position <"<<index+1<<", "<<probeCount+1<<"> of ScopeTable# "<<this->getID()<<endl;
    return true;
}


SymbolInfo* ScopeTable::lookupSymbol(string symbolName)
{
    unsigned int index = this->getHashvalue(symbolName);
    SymbolInfo* curr = hashTable[index];
    int probeCount = 0;
    while(curr!=nullptr)
    {
        if(curr->getSymbolName()==symbolName)
        {
            //cout<<"\t'"<<symbolName<<"' found at position <"<<index+1<<", "<<probeCount+1<<"> of ScopeTable# "<<this->getID()<<endl;
            return curr;
        }
        curr = curr->getNextSymbol();
        probeCount++;
    }
    return nullptr;
}


bool ScopeTable::deleteSymbol(string symbolName)
{
    unsigned int index = this->getHashvalue(symbolName);
    SymbolInfo* curr = hashTable[index];
    if(curr==nullptr)
    {
        //cout<<"\tNot found in the current ScopeTable# "<<this->getID()<<endl;
        return false;
    }
    int probeCount = 0;
    if(curr->getSymbolName()==symbolName)
    {
        hashTable[index] = curr->getNextSymbol();
       // cout<<"\tDeleted '"<<symbolName<<"' from position <"<<index+1<<", "<<probeCount+1<<"> of ScopeTable# "<<this->getID()<<endl;
        return true;
    }
    SymbolInfo* prev = curr;
    while(curr!=nullptr)
    {
        if(curr->getSymbolName()==symbolName)
        {
            prev->setNextSymbol(curr->getNextSymbol());
            delete curr;
            //cout<<"Deleted '"<<symbolName<<"' from position <"<<index<<", "<<probeCount+1<<"> of ScopeTable# "<<this->getID()<<endl;
            return true;
        }
        prev = curr;
        curr = curr->getNextSymbol();
        probeCount++;
    }
    //cout<<"\tNot found in the current ScopeTable# "<<this->getID()<<endl;
    return false;
}


void ScopeTable::printTable(FILE *ofile)
{
    //cout<<"\tScopeTable# "<<this->getID()<<endl;
    fprintf(ofile,"\tScopeTable# %s\n",this->getID().c_str());
    for(int i = 0; i< this->getTotalBuckets(); i++)
    {
        //cout<<"\t"<<i+1;
        fprintf(ofile,"\t%d",i+1);
        SymbolInfo *curr = hashTable[i];
        while(curr!=nullptr)
        {
            //cout<<" --> "<<"("<<curr->getSymbolName()<<","<<curr->getSymbolType()<<")";
            fprintf(ofile," --> (%s,%s)",curr->getSymbolName().c_str(),curr->getSymbolType().c_str());
            curr = curr->getNextSymbol();
        }
        //cout<<endl;
        fprintf(ofile,"\n");
    }
    
}






int ScopeTable::getTotalBuckets()
{
    return total_buckets;
}

string ScopeTable::getID()
{
    return ID;
}

void ScopeTable::setID(string ID)
{
    this->ID = ID;
}

ScopeTable* ScopeTable::getParentScope()
{
    return parentScope;
}

void ScopeTable::setParentScope(ScopeTable* parentScope)
{
    this->parentScope = parentScope;
}

int ScopeTable::getChildCount()
{
    return childCount;
}

void ScopeTable::setChildCount(int childCount)
{
    this->childCount = childCount;
}

