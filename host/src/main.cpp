//
//  main.cpp
//
//  Created by Arend Hintze on 2/6/13, modified and extended by Jory Schossau.
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

// parameters controlled by build script
#define DISTRIBUTION
#define GENES 2
#define LOCALMU false
#define MAPPING 0 // 0,1,2,3,4,5 for each 2-3 mapping permutation
#define SAMPLING 16383 // 7=every 8, 3=every4, 255=every256

#define randDouble ((double)rand()/(double)RAND_MAX)

int globalUpdate=0;
using namespace std;
double w=1.0; //selection strength

#define popSize (1<<10) // 1024

class tAgent{
	public:
		tAgent *ancestor;
		int nrPointingAtMe;
		int born;
		int tag;
		double genome[GENES];
		double p[3];
		double localMutationRate;
		double localMutationDelta;
		tAgent();
		~tAgent();
		void setupRand(void);
		void inherit(tAgent *from);

		void LOD(FILE *F);
		void LOD();
		void makeRPSprob(void);
};

double PM[3][3]={{0.0,0.0,0.0},{0.0,0.0,0.0},{1.0,0.0,0.0}};

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
void readPMfromCL(int argc, const char * argv[]);

// INPUTS (11 required) + (5 optional)
// ./prog 1 2 3 4 5 6 7 8 9 outFileName numUpdates [localMu [deltaMu [initStratA initStratB [initStratC]]]]

int main(int argc, const char * argv[])
{
	int i,j,g,k,x,y,nx,ny,deadGuy,newGuy;
	double maxFit;
	double localmu;
	double deltamu;
	FILE *PHYf;
	FILE *POPf;
	FILE *DISTf;
	char phyFileName[1<<10];
	char popFileName[1<<10];
	char distFileName[1<<10];
	bool useFile=false;
	bool useLocalMutationFlag=false;
	bool consistentStart=false;
	double init1=0.0,init2=0.0,init3=0.0;
	int generations; // these are updates, but we call them generations which is a misnomer
	map<int,double> popDynamic;
	readPMfromCL(argc, argv); // set the payoff matrix from command line params
	if (!useLocalMutationFlag)
	{
		localmu = 0.02f;
		deltamu = 1.0f;
	}
	if (argc >= 12){
		useFile = true;
		generations=atoi(argv[11]);
		if (argc >= 13){
			localmu=atof(argv[12]);
			cout << "mu: " << localmu << endl;
			if (argc >= 14){
				deltamu=atof(argv[13]);
				useLocalMutationFlag=true;
				cout << "deltamu: " << deltamu << endl;
				if (argc >=15) {
					consistentStart=true;
					init1=atof(argv[14]);
					init2=atof(argv[15]);
					cout << "start: [" << init1 << ", " << init2;
					if (argc >=17) {
						init3=atof(argv[16]);
						cout << ", " << init3;
					}
					cout << "]" << endl;
				}
			}
		}
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
	//srand(time(NULL)); // condor/windows compatible
	population.clear();
	for(i=0;i<popSize;i++){
		tAgent *A=new tAgent;
		A->setupRand();
		//A->tag=rand()%3;
		A->tag=4;
		if (consistentStart)
			A->tag=3;
		if (GENES == 2)
			switch(A->tag){
				case 0: // all strategy A
					A->genome[0]=0.0;
					A->genome[1]=1.0;
					A->localMutationRate=0.0;
					A->localMutationDelta=deltamu;
					break;
				case 1: // all strategy B
					A->genome[0]=1.0;
					A->genome[1]=0.0;
					A->localMutationRate=0.0;
					A->localMutationDelta=deltamu;
					break;
				case 2: // all strategy C
					A->genome[0]=1.0;
					A->genome[1]=1.0;
					A->localMutationRate=0.0;
					A->localMutationDelta=deltamu;
					break;
				case 3: // all with the supplied strategy ratios
					A->genome[0]=init1;
					A->genome[1]=init2;
					A->localMutationRate=localmu;
					A->localMutationDelta=deltamu;
					break;
				default: // all with random strategy ratios
					A->setupRand();
					A->localMutationRate=localmu;
					A->localMutationDelta=deltamu;
					break;
			}
		else
			switch(A->tag){
				case 0: // all strategy A
					A->genome[0]=1.0;
					A->genome[1]=0.0;
					A->genome[2]=0.0;
					A->localMutationRate=0.0;
					A->localMutationDelta=deltamu;
					break;
				case 1: // all strategy B
					A->genome[0]=0.0;
					A->genome[1]=1.0;
					A->genome[2]=0.0;
					A->localMutationRate=0.0;
					A->localMutationDelta=deltamu;
					break;
				case 2: // all strategy C
					A->genome[0]=0.0;
					A->genome[1]=0.0;
					A->genome[2]=1.0;
					A->localMutationRate=0.0;
					A->localMutationDelta=deltamu;
					break;
				case 3: // all with supplied strategy ratios
					A->genome[0]=init1;
					A->genome[1]=init2;
					A->genome[2]=init3;
					A->localMutationRate=localmu;
					A->localMutationDelta=deltamu;
					break;
				default: // all with random strategy ratios
					A->setupRand();
					A->localMutationRate=localmu;
					A->localMutationDelta=deltamu;
					break;
			}
		A->makeRPSprob();
		population.push_back(A);
	}
	recalculateEverything();
	for(globalUpdate=1;globalUpdate<generations;globalUpdate++){
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
		if((globalUpdate& SAMPLING )==0){
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
			for(i=0;i<GENES;i++)
				genome[i]=randDouble;
		}

		void tAgent::inherit(tAgent *from){
			int i;
			from->nrPointingAtMe++;
			ancestor=from;
			tag=from->tag;
			localMutationRate=from->localMutationRate;
			localMutationDelta=from->localMutationDelta;
			for(i=0;i<GENES;i++)
				genome[i]=from->genome[i];
			if(randDouble<localMutationRate){
				if (LOCALMU == true) {
					for(i=0;i<GENES;i++)
					{
						genome[i]+=(randDouble*2-1)*localMutationDelta;
						if (genome[i] < 0.0f)
							genome[i] = 0.0f;
						if (genome[i] > 1.0f)
							genome[i] = 1.0f;
					}
				} else {
					for(i=0;i<GENES;i++)
					{
						genome[i]=randDouble;
					}
				}
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
			if (GENES == 3) {
				p[0]=genome[0];
				p[1]=genome[1];
				p[2]=genome[2];
				s=genome[0]+genome[1]+genome[2];
				if(s > 0.00001){
					for(i=0;i<3;i++)
						p[i]/=s;
				} else {
					p[0] = p[1] = p[2] = 0.0;
				}
			} else {
				switch(MAPPING) {
					case 0:
						p[0]=genome[0]*genome[1];
						p[1]=genome[0]*(1.0-genome[1]);
						p[2]=(1.0-genome[0])*genome[1];
						break;
					case 1:
						p[0]=genome[0]*genome[1];
						p[1]=(1.0-genome[0])*genome[1];
						p[2]=genome[0]*(1.0-genome[1]);
						break;
					case 2:
						p[0]=genome[0]*(1.0-genome[1]);
						p[1]=genome[0]*genome[1];
						p[2]=(1.0-genome[0])*genome[1];
						break;
					case 3:
						p[0]=genome[0]*(1.0-genome[1]);
						p[1]=(1.0-genome[0])*genome[1];
						p[2]=genome[0]*genome[1];
						break;
					case 4:
						p[0]=(1.0-genome[0])*genome[1];
						p[1]=genome[0]*(1.0-genome[1]);
						p[2]=genome[0]*genome[1];
						break;
					case 5:
						p[0]=(1.0-genome[0])*genome[1];
						p[1]=genome[0]*genome[1];
						p[2]=genome[0]*(1.0-genome[1]);
						break;
				}
				s = genome[0] + genome[1] - genome[0]*genome[1];
				if (genome[0]+genome[1] > 0.0001) {
					p[0] /= s;
					p[1] /= s;
					p[2] /= s;
				}
			}
		}


		// *** play agents against each other

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
			cout<<(meanP/(double)(popSize-1))<<" "<<(meanF/(double)(popSize-1))<<" "<<population[j]->genome[0]<<" "<<population[j]->genome[1];
		}

		double play(tAgent *A,tAgent *B){
			double S=0.0;
			int i,j;
			for(i=0;i<3;i++)
				for(j=0;j<3;j++)
					S+=PM[i][j]*(A->p[i]*B->p[j]);
			return S;
		}
