#include <string>
using namespace std;

class SymbolInfo
{
private:
    string symbolName;
    string symbolType;
    SymbolInfo *nextSymbol;
public:
    SymbolInfo();
    SymbolInfo(const string& name, const string& type);
    ~SymbolInfo();
    string getSymbolName();
    string getSymbolType();
    SymbolInfo *getNextSymbol();
    void setNextSymbol(SymbolInfo *symbol);
};

SymbolInfo::SymbolInfo(){}

SymbolInfo::SymbolInfo(const string& name, const string& type):symbolName(name),symbolType(type)
{
    nextSymbol = nullptr;
}

SymbolInfo::~SymbolInfo()
{

}


string SymbolInfo::getSymbolName()
{
    return this->symbolName;
}

string SymbolInfo::getSymbolType()
{
    return this->symbolType;
}

SymbolInfo* SymbolInfo::getNextSymbol()
{
    return this->nextSymbol;
}

void SymbolInfo::setNextSymbol(SymbolInfo *symbol)
{
    this->nextSymbol = symbol;
}



