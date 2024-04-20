#include<bits/stdc++.h>
#include "2005117_SymbolTable.h"

using namespace std;

const int MAX_SIZE = 100;

int main()
{
    ifstream file("input.txt");
    freopen("VSoutput.txt", "w", stdout);

    string firstLine;
    getline(file,firstLine);
    int total_buckets = stoi(firstLine);

    SymbolTable *symbolTable = new SymbolTable(total_buckets);

    string line;
    string array[MAX_SIZE];
    int cmdCount = 0;

    while (getline(file, line))
    {
        cmdCount++;
        int arrayIndex = 0;
        istringstream iss(line);
        string token;

        while (getline(iss, token, ' ')) {
            array[arrayIndex++] = token;

        }
        cout<<"Cmd "<<cmdCount<<": ";
        for(int i =0;i<arrayIndex;i++)
        {
            cout<<array[i];
            if(i!=arrayIndex-1) cout<<" ";
        }
        cout<<endl;
        if (array[0] == "I")
        {
            if(arrayIndex==3)
            {
            string symbolName, symbolType;
            symbolName  = array[1];
            symbolType = array[2];
            SymbolInfo *symbolInfo = new SymbolInfo(symbolName, symbolType);
            symbolTable->insertSymbol(symbolInfo);
            }
             else
            {
                cout<<"\tWrong number of arguments for the command "<<array[0]<<endl;
            }
        }
        else if (array[0] == "L")
        {
            if(arrayIndex==2)
            {
            string symbolName;
            symbolName  = array[1];
            symbolTable->lookupSymbol(symbolName);
            }
             else
            {
                cout<<"\tWrong number of arguments for the command "<<array[0]<<endl;
            }

        }
        else if (array[0] == "D")
        {
            if(arrayIndex==2)
            {
            string symbolName;
            symbolName  = array[1];
            symbolTable->removeSymbol(symbolName);
            }
             else
            {
                cout<<"\tWrong number of arguments for the command "<<array[0]<<endl;
            }

        }
        else if (array[0] == "P")
        {
            if(arrayIndex==2)
            {
            string param;
            param = array[1];
            if (param == "A")
                symbolTable->printAll();
            else if (param=="C")
                symbolTable->printCur();
                else
                    cout<<"\tInvalid argument for the command "<<array[0]<<endl;
            }
             else
            {
                cout<<"\tWrong number of arguments for the command "<<array[0]<<endl;
            }


        }
        else if (array[0] == "S")
        {
            if(arrayIndex==1)
            {
              symbolTable->enterScope();
            }
             else
            {
                cout<<"\tWrong number of arguments for the command "<<array[0]<<endl;
            }

        }
        else if (array[0] == "E")
        {
            if(arrayIndex==1)
            {
               symbolTable->exitScope();
            }
             else
            {
                cout<<"\tWrong number of arguments for the command "<<array[0]<<endl;
            }


        }
        else if (array[0] == "Q")
        {
            if(arrayIndex==1)
            {
               delete symbolTable;
            }
             else
            {
                cout<<"\tWrong number of arguments for the command "<<array[0]<<endl;
            }

        }
        else
        {
            cout<<"\tInvalid command"<<endl;
        }

    }
    return 0;
}

