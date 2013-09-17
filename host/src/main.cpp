//
//  main.cpp
//  CrowdSourcing
//
//  Created by Arend Hintze on 2/6/13.
//  Copyright (c) 2013 MPI-BERLIN. All rights reserved.
//

#include <stdlib.h>
#include <stdio.h>
#include <vector>
#include <iostream>
#include <math.h>
#include <algorithm>
#include <time.h>
#include <map>
#include <math.h>
#include <string.h>

#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

#define DISTRIBUTION

#define randDouble ((double)rand()/(double)RAND_MAX)

int globalUpdate=0;
using namespace std;
double w=1.0; //selection strength

//#define popSize (1<<12) // 4096
#define popSize (1<<10) // 1024
//#define popSize (1<<9) // 512
//#define popSize (1<<8) // 256
//#define popSize (1<<7) // 128 or ~11x11
//#define popSize (1<<6) // 64
//#define popSize (1<<5) // 32
//#define popSize (1<<4) // 16

class tAgent{
public:
    tAgent *ancestor;
    int nrPointingAtMe;
    int born;
	int tag;
    double genome[2];
    double p[3];
    double localMutationRate;
    tAgent();
    ~tAgent();
    void setupRand(void);
    void inherit(tAgent *from);

    void LOD(FILE *F);
    void LOD();
    void makeRPSprob(void);
};

//double PM[3][3]={{0.5,10.0,10.0},{1.0,0.5,0.0},{0.0,1.0,0.5}};
//y=\frac{\left(cos\left(\left(\frac{pi}{5}\right)x\right)+1\right)}{2}
//double PM[3][3]={{0.5,0.0,1.0},{1.0,0.5,0.0},{1.0,2.0,6.0}};
//double PM[3][3]={{0.5,0.0,1.0},{1.0,0.5,0.0},{0.0,1.0,0.5}};
//double PM[3][3]={{0.0,0.0,1.0},{1.0,0.0,0.0},{0.0,1.0,0.0}};
//double PM[3][3]={{0.0,1.0,0.0},{0.4,0.0,0.0},{0.28571,0.28571,0.0}};
//double PM[3][3]={{0.0,1.0,0.0},{1.0,0.0,0.0},{0.5,0.5,0.0}};
//double PM[3][3]={{1.0,2.0,2.0},{0.0,1.0,4.0},{2.0,2.0,1.0}};
//double PM[3][3]={{9.0,18.0,6.0},{0.0,9.0,14.0},{19.0,7.0,9.0}};
//double PM[3][3]={{0.0,1.0,1.0},{1.0,0.0,1.0},{1.0,1.0,0.0}};
double PM[3][3]={{0.0,0.0,0.0},{0.0,0.0,0.0},{1.0,0.0,0.0}};
//double PM[3][3]={{0.0,1.0,0.0},{0.6,0.0,0.0},{0.375,0.375,0.0}};
//double PM[3][3]={{0.0,1.0,0.0},{0.8,0.0,0.0},{0.44444,0.44444,0.0}};
//double PM[3][3]={{0.0,1.0,0.0},{1.0,0.0,0.0},{0.5,0.5,0.0}};
double PM_SCISSORS[3][3]={{0.0,0.0,1.0},{2.0,0.0,0.0},{0.0,3.0,0.0}};
double PM_ROCK[3][3]={{0.0,0.0,3.0},{2.0,0.0,0.0},{0.0,1.0,0.0}};

vector<tAgent*> population;
double payoffs[popSize][popSize];
double sumOfPayoffs[popSize];
double fitness[popSize];

void printDistribution(FILE *F);
void recalculateEverything(void);
void showPayoffs(void);
void popCheck(void);
void recalculateSingle(int who);
double play(tAgent *A,tAgent *B);
void xFadeTables(double target[][3], const double from[][3], const double to[][3], int length, int currentTimestep);
void readPMfromCL(int argc, const char * argv[]);

// INPUTS (12)
// prog 1 2 3 4 5 6 7 8 9 phylogenyFileName generations transitionPeriod

int main(int argc, const char * argv[])
{
    int i,j,g,k,x,y,nx,ny,deadGuy,newGuy;
    double maxFit;
    FILE *PHYf;
    FILE *POPf;
	 FILE *DISTf;
    char phyFileName[1<<10];
	 char popFileName[1<<10];
	 char distFileName[1<<10];
	 bool useFile=false;
	 int generations;
	 int transitionPeriod; // how many generations to go from 1 table to the other
	 bool dynamicEnvironment=false; // do we use oscillating environment?
    map<int,double> popDynamic;
	 readPMfromCL(argc, argv); // set the payoff matrix from command line params
	 if (argc >= 12){
		useFile = true;
		generations=atoi(argv[11]);
		if (argc >= 13){
			transitionPeriod=atoi(argv[12]);
			dynamicEnvironment=true;
		} else
			transitionPeriod=0; // 0 will cause an error if used in staticEnvironment
		
	 } else
		 generations=500000;
	 if (useFile) {
		 strcpy(phyFileName,"");
		 strcat(phyFileName,argv[10]);
		 strcat(phyFileName,".phy");
		 strcpy(popFileName,"");
		 strcat(popFileName,argv[10]);
		 strcat(popFileName,".pop");
		 strcpy(distFileName,"");
		 strcat(distFileName,argv[10]);
		 strcat(distFileName,".dist");
		 POPf=fopen(popFileName,"w+t");
		 fprintf(POPf,"generation,paper,rock,scissors,mixed\n");
	 } else
		 printf("paper,rock,scissors,mixed\n");
    srand((int)getpid()); // this is not cross-platofrm. Changed for condor compat.
    //srand(time(NULL)); // condor compatible
    population.clear();
    for(i=0;i<popSize;i++){
        tAgent *A=new tAgent;
        A->setupRand();
		//A->tag=rand()%3;
		A->tag=3;
        switch(A->tag){
            case 0:
                A->genome[0]=0.0;
                A->genome[1]=1.0;
                A->localMutationRate=0.0;
                break;
            case 1:
                A->genome[0]=1.0;
                A->genome[1]=0.0;
                A->localMutationRate=0.0;
                break;
            case 2:
                A->genome[0]=1.0;
                A->genome[1]=1.0;
                A->localMutationRate=0.0;
                break;
            default:
                //A->genome[0]=0.5;
                //A->genome[1]=0.5;
					 A->setupRand();
                A->localMutationRate=0.02;
                break;
        }
        A->makeRPSprob();
        population.push_back(A);
    }
    recalculateEverything();
    for(globalUpdate=1;globalUpdate<generations;globalUpdate++){
			if (dynamicEnvironment) {
			  xFadeTables(PM,PM_ROCK,PM_SCISSORS,transitionPeriod,globalUpdate);
			}
        //showPayoffs();
        maxFit=0.0;
        for(i=0;i<popSize;i++){
            fitness[i]=exp(w*(sumOfPayoffs[i]/(double)(popSize-1)));
            if(maxFit<fitness[i])
                maxFit=fitness[i];
        }

		  do{
				newGuy=rand()%popSize;
		  }while(randDouble>(fitness[newGuy]/maxFit));
		  do{
				deadGuy=rand()%popSize;
		  }while(deadGuy==newGuy);
		  population[deadGuy]->nrPointingAtMe--;
		  if(population[deadGuy]->nrPointingAtMe==0)
				delete population[deadGuy];
		  population[deadGuy]=new tAgent;
		  population[deadGuy]->inherit(population[newGuy]);
		  recalculateSingle(deadGuy);
		  if((globalUpdate&16383)==0){
		  //if((globalUpdate&8191)==0){
        //if((globalUpdate&4095)==0){
        //if((globalUpdate&2047)==0){
        //if((globalUpdate&1023)==0){
        //if((globalUpdate&511)==0){
        //if((globalUpdate&255)==0){
        //if((globalUpdate&127)==0){
        //if((globalUpdate&63)==0){
        //if((globalUpdate&31)==0){
        //if((globalUpdate&15)==0){
			  cout<<globalUpdate<<" ";
            popCheck();
            cout<<endl;
            popDynamic.clear();
            for(i=0;i<popSize;i++)
                popDynamic[population[i]->tag]+=1.0;
				if (useFile)
            	fprintf(POPf,"%i,%f,%f,%f,%f\n",globalUpdate,popDynamic[0]/(double)popSize,popDynamic[1]/(double)popSize,popDynamic[2]/(double)popSize,popDynamic[3]/(double)popSize);
				else
            	printf("%f,%f,%f,%f\n",popDynamic[0]/(double)popSize,popDynamic[1]/(double)popSize,popDynamic[2]/(double)popSize,popDynamic[3]/(double)popSize);
        }
    }
	 if (useFile) {
		 PHYf=fopen(phyFileName,"w+t");
		 population[0]->LOD(PHYf);
		 fclose(PHYf);
#ifdef DISTRIBUTION
		 DISTf=fopen(distFileName,"w+t");
		 printDistribution(DISTf); 
		 fclose(DISTf);
#endif
	 }else{
		 population[0]->LOD();
	}
    return 0;
}

void readPMfromCL(int argc, const char * argv[])
{
	PM[0][0]=strtod(argv[1],NULL);
	PM[0][1]=strtod(argv[2],NULL);
	PM[0][2]=strtod(argv[3],NULL);
	PM[1][0]=strtod(argv[4],NULL);
	PM[1][1]=strtod(argv[5],NULL);
	PM[1][2]=strtod(argv[6],NULL);
	PM[2][0]=strtod(argv[7],NULL);
	PM[2][1]=strtod(argv[8],NULL);
	PM[2][2]=strtod(argv[9],NULL);
}

tAgent::tAgent(){
    ancestor=NULL;
    nrPointingAtMe=1;
    born=globalUpdate;
}

tAgent::~tAgent(){
    if(ancestor!=NULL){
        ancestor->nrPointingAtMe--;
        if(ancestor->nrPointingAtMe==0)
            delete ancestor;
    }
}

void tAgent::setupRand(void){
    int i;
    for(i=0;i<2;i++)
        genome[i]=randDouble;
}

void tAgent::inherit(tAgent *from){
    int i;
    from->nrPointingAtMe++;
    ancestor=from;
    tag=from->tag;
    localMutationRate=from->localMutationRate;
    if(randDouble<localMutationRate){
        for(i=0;i<2;i++)
            genome[i]=randDouble;
    }
    else{
        for(i=0;i<2;i++)
            genome[i]=from->genome[i];
    }
    makeRPSprob();
}

void tAgent::LOD(){
    if(ancestor!=NULL)
        ancestor->LOD();
    else
        printf("generation,g0,g1,scissors,rock,paper\n");
    printf("%i,%f,%f,%f,%f,%f\n",born
            ,genome[0],genome[1]
            ,p[0],p[1],p[2]);
}

void tAgent::LOD(FILE *F){
    if(ancestor!=NULL)
        ancestor->LOD(F);
    else
        fprintf(F,"generation,g0,g1,scissors,rock,paper\n");
    fprintf(F,"%i,%f,%f,%f,%f,%f\n",born
            ,genome[0],genome[1]
            ,p[0],p[1],p[2]);
}

void tAgent::makeRPSprob(void){
    int i;
    double s=0.0;
    p[0]=genome[0]*genome[1];
    p[1]=genome[0]*(1.0-genome[1]);
    p[2]=(1.0-genome[0])*genome[1];
    s=p[0]+p[1]+p[2];
    if(s==0.0){
        for(i=0;i<3;i++)
            p[i]=1.0/3.0;
    } else
        for(i=0;i<3;i++)
            p[i]/=s;
}


// *** regular functions

void recalculateEverything(void){
    int i,j;
    for(i=0;i<popSize;i++){
        fitness[i]=0.0;
        sumOfPayoffs[i]=0.0;
        for(j=0;j<popSize;j++)
            payoffs[i][j]=0.0;
    }
    for(i=0;i<popSize;i++)
        for(j=i+1;j<popSize;j++){
            payoffs[i][j]+=play(population[i], population[j]);
            payoffs[j][i]+=play(population[j], population[i]);
        }
    for(i=0;i<popSize;i++){
        for(j=0;j<popSize;j++)
            if(i!=j)
                sumOfPayoffs[i]+=payoffs[i][j];
    }
}

void printDistribution(FILE *F){
	int i;
	for(i=popSize-1;i>0;--i){
		fprintf(F,"%f,%f,%f\n",population[i]->p[0],population[i]->p[1],population[i]->p[2]);
	}
}

void recalculateSingle(int who){
    int i,j;
    sumOfPayoffs[who]=0.0;
    for(i=0;i<popSize;i++){
        sumOfPayoffs[i]-=payoffs[i][who];
        payoffs[i][who]=0.0;
        payoffs[who][i]=0.0;
    }
    for(i=0;i<popSize;i++)
        if(i!=who){
            payoffs[i][who]+=play(population[i], population[who]);
            payoffs[who][i]+=play(population[who], population[i]);
        }
    for(i=0;i<popSize;i++)
        if(i!=who){
            sumOfPayoffs[i]+=payoffs[i][who];
            sumOfPayoffs[who]+=payoffs[who][i];
        }
}
void showPayoffs(void){
    int i,j;
    for(j=0;j<popSize;j++){
        for(i=0;i<popSize;i++)
            printf("%0.02f ",payoffs[i][j]);
        printf("\n");
    }
}

void popCheck(void){
    int i,j=0;
    double meanP=0.0,meanF=0.0,maxFit=0.0;
    for(i=0;i<popSize;i++){
        meanP+=sumOfPayoffs[i]/(double)(popSize-1);
        meanF+=fitness[i];
        if(fitness[i]>maxFit){
            j=i;
            maxFit=fitness[i];
        }
    }
    cout<<(meanP/(double)(popSize-1))<<" "<<(meanF/(double)(popSize-1))<<" "<<population[j]->genome[0]<<" "<<population[j]->genome[0];
}

double play(tAgent *A,tAgent *B){
    double S=0.0;
    int i,j;
    for(i=0;i<3;i++)
        for(j=0;j<3;j++)
            S+=PM[i][j]*(A->p[i]*B->p[j]);
    return S;
}

void xFadeTables(double target[][3], double const from[][3], double const to[][3], int length, int currentTimestep){
	for (int r=2; r>=0; --r){
		for (int c=2; c>=0; --c){
			target[r][c] = from[r][c]*(0.5*cos((currentTimestep*3.14159265359)/length)+0.5) + to[r][c]*(0.5*cos((length*3.14159265359-currentTimestep*3.14159265359)/length)+0.5);
		}
	}
}
