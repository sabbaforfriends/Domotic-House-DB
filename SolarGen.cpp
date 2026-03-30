#include <iostream>
#include <random>
#include <cmath>
using namespace std;


// picco massimo
const double Amin = 2;
const double Amax = 3;

// larghezza
const double Cmin = -4.3;
const double Cmax = -4.0;

double f(double a, double c, double x){
    double b = 12;
    double sopra = pow((x/60)-b,2.0);
    double sotto = pow(c, 2.0);
    double esp = -(sopra/sotto);
    return a*pow(2.718281828459,esp);
}

int main() {
    
    int giorni = 60;
    for(int i = 0; i < giorni;++i){
        double x =0;
        while(x <= 23*60 + 59){
            double a = ((double)(rand()%10))/10+Amin;
            double c = ((double)(rand()%4))/10+Cmin;
            printf(", %.2f),\n", f(a, c, x));
            x += 10;
        }
    }
     
    int a;
    cin >> a;

    return 0;
}

