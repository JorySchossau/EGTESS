/********************************************************************
*  sample.cu
*  CUDA punishment with radius replacement
*********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
//#include <cutil.h>
#include <vector>
#include <time.h>
#include <iostream>
#include <math.h>
#include <map>

using namespace std;

#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

#define KISSRND (((((rndZ=36969*(rndZ&65535)+(rndZ>>16))<<16)+(rndW=18000*(rndW&65535)+(rndW>>16)) )^(rndY=69069*rndY+1234567))+(rndX^=(rndX<<17), rndX^=(rndX>>13), rndX^=(rndX<<5)))
#define INTABS(number) (((((0x80)<<((sizeof(int)-1)<<3))&number) ? (~number)+1 : number))

float PM[3][3]={{0.0,0.0,0.0},{0.0,0.0,0.0},{1.0,0.0,0.0}};

struct agent{
	float fitness;
	float G[2],P[3];
};

void readPMfromCL(int argc, const char * argv[]);

/************************************************************************/
/* Init CUDA                                                            */
/************************************************************************/
#if __DEVICE_EMULATION__

bool InitCUDA(int theDevice){return true;}

#else
bool InitCUDA(int theDevice)
{
	int count = 0;
	int i = 0;

	cudaGetDeviceCount(&count);
	if(count == 0) {
		fprintf(stderr, "There is no device.\n");
		return false;
	}

	for(i = 0; i < count; i++) {
		cudaDeviceProp prop;
		if(cudaGetDeviceProperties(&prop, i) == cudaSuccess) {
			if(prop.major >= 1) {
				break;
			}
		}
	}
	if(i == count) {
		fprintf(stderr, "There is no device supporting CUDA.\n");
		return false;
	}
//	cudaSetDevice(theDevice);
//	cudaSetDevice(i);
//	printf("CUDA initialized on %i.\n",i);
	return true;
}

#endif

__global__ static void makePopulationPureStrategyRandom(int popSizeX,agent* genotypeDevice,int rndW, int rndX, int rndY, int rndZ){
	int i = (blockIdx.x * blockDim.x) + threadIdx.x;
	int j = (blockIdx.y * blockDim.y) + threadIdx.y;
	int index=i*popSizeX+j;
	int t;
	rndW+=index; // make random seeds unique from one another by including index
	rndX+=index;
	rndY+=index;
	rndZ+=index;
	t=KISSRND;
	t=INTABS(t);
	switch(t%3){
		case 0:
			genotypeDevice[index].G[0]=0.0;
			genotypeDevice[index].G[1]=1.0;
		break;
		case 1:
			genotypeDevice[index].G[0]=1.0;
			genotypeDevice[index].G[1]=0.0;
		break;
		case 2:
			genotypeDevice[index].G[0]=1.0;
			genotypeDevice[index].G[1]=1.0;
		break;
	}
	float s=0.0;
	genotypeDevice[index].P[0]=genotypeDevice[index].G[0]*genotypeDevice[index].G[1];
	genotypeDevice[index].P[1]=genotypeDevice[index].G[0]*(1.0-genotypeDevice[index].G[1]);
	genotypeDevice[index].P[2]=(1.0-genotypeDevice[index].G[0])*genotypeDevice[index].G[1];
	s=genotypeDevice[index].P[0]+genotypeDevice[index].P[1]+genotypeDevice[index].P[2];
	if(s==0.0){
		for(int n=0;n<3;n++)
			genotypeDevice[index].P[n]=1.0/3.0;
	} else
		for(int n=0;n<3;n++)
			genotypeDevice[index].P[n]/=s;
}

__global__ static void makePopulationUniformlyRandom(int popSizeX,agent* genotypeDevice,int rndW, int rndX, int rndY, int rndZ){
	int i = (blockIdx.x * blockDim.x) + threadIdx.x;
	int j = (blockIdx.y * blockDim.y) + threadIdx.y;
	int index=i*popSizeX+j;
	int R[4];
	rndW+=index; // make random seeds unique from one another by including index
	rndX+=index;
	rndY+=index;
	rndZ+=index;
	for(int n=0;n<4;n++){
		int A=KISSRND;
		R[n]=INTABS(A);
	}
	rndW=R[0]; rndX=R[1]; rndY=R[2]; rndZ=R[3];
	genotypeDevice[index].fitness=0.0;
	for(int n=0;n<2;n++){
		int r=KISSRND;
		r=INTABS(r);
		genotypeDevice[index].G[n]=(float)(r&65535)/(float)65535;
	}
	float s=0.0;
	genotypeDevice[index].P[0]=genotypeDevice[index].G[0]*genotypeDevice[index].G[1];
	genotypeDevice[index].P[1]=genotypeDevice[index].G[0]*(1.0-genotypeDevice[index].G[1]);
	genotypeDevice[index].P[2]=(1.0-genotypeDevice[index].G[0])*genotypeDevice[index].G[1];
	s=genotypeDevice[index].P[0]+genotypeDevice[index].P[1]+genotypeDevice[index].P[2];
	if(s==0.0){
		for(int n=0;n<3;n++)
			genotypeDevice[index].P[n]=1.0/3.0;
	} else
		for(int n=0;n<3;n++)
			genotypeDevice[index].P[n]/=s;
}

__global__ static void computeFitness(int popSizeX,int popSize,agent* genotypeDevice,float p00,float p01,float p02,float p10,float p11,float p12,float p20,float p21,float p22){
	int i = (blockIdx.x * blockDim.x) + threadIdx.x;
	int j = (blockIdx.y * blockDim.y) + threadIdx.y;
	int index=i*popSizeX+j;
	int w,x,y;
	float fitness=0.0;
	float PM[3][3];
	PM[0][0]=p00; PM[0][1]=p01; PM[0][2]=p02;
	PM[1][0]=p10; PM[1][1]=p11; PM[1][2]=p12;
	PM[2][0]=p20; PM[2][1]=p21; PM[2][2]=p22;
	//for(w=0;w<popSize;w++)
	for(w=1;w<256;w++){
		int who=(index+w)%popSize;
		for(x=0;x<3;x++)
			for(y=0;y<3;y++)
				fitness+=PM[x][y]*(genotypeDevice[index].P[x]*genotypeDevice[who].P[y]);
	}
	genotypeDevice[index].fitness=fitness;
}

__global__ static void makeReplacement(int popSizeX,int popSize, agent *genotypeDevice,agent *replacementGenotypeDevice,float maxFit,float mutationRate,int rndW, int rndX, int rndY, int rndZ){
	int i = (blockIdx.x * blockDim.x) + threadIdx.x;
	int j = (blockIdx.y * blockDim.y) + threadIdx.y;
	int index=i*popSizeX+j;
	int ID;
	int fInt;
	float f;
	int R[4];
	rndW+=index; // make random seeds unique from one another by including index
	rndX+=index;
	rndY+=index;
	rndZ+=index;
	for(int n=0;n<4;n++){
		int A=KISSRND;
		R[n]=INTABS(A);
	}
	rndW=R[0]; rndX=R[1]; rndY=R[2]; rndZ=R[3];
	do{
		int A=KISSRND;
		ID=INTABS(A);
		ID=ID%popSize;
		fInt=KISSRND;
		fInt=(INTABS(fInt))&65535;
		f=(float)fInt/(float)65535;
	}while(f>(genotypeDevice[ID].fitness/maxFit));
	bool mutated=false;
	for(int n=0;n<2;n++){
		fInt=KISSRND;
		fInt=(INTABS(fInt))&65535;
		f=(float)fInt/(float)65535;
		if(f>=mutationRate)
			replacementGenotypeDevice[index].G[n]=genotypeDevice[ID].G[n];
		else{
			fInt=KISSRND;
			fInt=(INTABS(fInt))&65535;
			f=(float)fInt/(float)65535;
			replacementGenotypeDevice[index].G[n]=f;
		}
	}
	float s=0.0;
	replacementGenotypeDevice[index].P[0]=replacementGenotypeDevice[index].G[0]*replacementGenotypeDevice[index].G[1];
	replacementGenotypeDevice[index].P[1]=replacementGenotypeDevice[index].G[0]*(1.0-replacementGenotypeDevice[index].G[1]);
	replacementGenotypeDevice[index].P[2]=(1.0-replacementGenotypeDevice[index].G[0])*replacementGenotypeDevice[index].G[1];
	s=replacementGenotypeDevice[index].P[0]+replacementGenotypeDevice[index].P[1]+replacementGenotypeDevice[index].P[2];
	if(s==0.0){
		for(int n=0;n<3;n++)
			replacementGenotypeDevice[index].P[n]=1.0/3.0;
	} else
		for(int n=0;n<3;n++)
			replacementGenotypeDevice[index].P[n]/=s;
}
/*
__global__ static void insertReplacement(int repSizeX, int popSize, int offset, int *genotypeDevice,int *replacementGenotypeDevice){
	int i = (blockIdx.x * blockDim.x) + threadIdx.x;
	int j = (blockIdx.y * blockDim.y) + threadIdx.y;
	int index=i*repSizeX+j;
	int ID=(offset+index)%popSize;
	genotypeDevice[ID]=replacementGenotypeDevice[index];
}*/

int main(int argc, const char* argv[]){
	//very first check if we have cuda on this machine at all...
	if(!InitCUDA(0)) {
		printf("InitCUDA not working, don't know why not...\n");
		return 0;
	} else
		printf("InitCUDA passed\n");
	//let's define our variables needed
	//all memory related variables
	agent *genotypeDeviceA,*genotypeDeviceB,*swap;
	agent *genotypeHost;
	
	//other variables
	int popSizeZ=atoi(argv[2]); //30
	int popSizeX=popSizeZ*16;
	int popSizeY=popSizeZ*16;
	int popSize=popSizeX*popSizeY;
	int i,j,update;
	float maxFit;
	float Phost[3];
	float mutationRate=atof(argv[3]);//0.02
	int updates=atoi(argv[4]);
	FILE *F1=fopen(argv[1],"w+t");
	fprintf(F1,"update,p0,p1,p2\n");
	//kernel call and correct dimensions thereof
	cudaError_t error;
	dim3 threadsPerBlockPop(16, 16);
	dim3 numBlocksPop(popSizeX/threadsPerBlockPop.x, popSizeY/threadsPerBlockPop.y);
	//setup cude device
	error=cudaSetDevice(0);
	printf("try to set device 0\n");
	error=cudaMalloc((void**)&genotypeDeviceA,sizeof(agent)*(popSize));
	if(error!=cudaSuccess){
		printf("didn't work, try device 1\n");
		error=cudaSetDevice(1);
		error=cudaMalloc((void**)&genotypeDeviceA,sizeof(agent)*(popSize));
		if(error!=cudaSuccess){
			printf("sorry could not call the right device, or not enough memory\n");
			exit(0);
		}
	}
	error=cudaMalloc((void**)&genotypeDeviceB,sizeof(agent)*(popSize));
	if(error!=cudaSuccess){
		printf("sorry could not allocate the copyPopulation\n");
		exit(0);
	}
	srand(time(NULL));
	//allocate the memory used on the host
	genotypeHost=(agent*)malloc(sizeof(agent)*popSize);
	if(genotypeHost==NULL){
		printf("could not allocate enough host memory...\n");
		exit(0);
	} else
		printf("alloc for host memory affirmative!\n");
	//load first genotype and phenotype into all memory
	if(mutationRate==0.0)
		makePopulationPureStrategyRandom<<<numBlocksPop,threadsPerBlockPop>>>(popSizeX,genotypeDeviceA,rand(),rand(),rand(),rand());
	else
		makePopulationUniformlyRandom<<<numBlocksPop,threadsPerBlockPop>>>(popSizeX,genotypeDeviceA,rand(),rand(),rand(),rand());
	cudaThreadSynchronize();
	readPMfromCL(argc, argv); // set the payoff matrix from command line params
	printf("population is uniform\n");
	for(update=0;update<updates;update++){
		//execute fitness computation here, NOW!!!!!!!
		computeFitness<<<numBlocksPop,threadsPerBlockPop>>>(popSizeX,popSize,genotypeDeviceA,PM[0][0],PM[0][1],PM[0][2],PM[1][0],PM[1][1],PM[1][2],PM[2][0],PM[2][1],PM[2][2]);
		cudaThreadSynchronize();
		//find max fit
		error=cudaMemcpy(genotypeHost, genotypeDeviceA, sizeof(agent) * popSize, cudaMemcpyDeviceToHost);
//		for(int n=0;n<20;n++)
//			printf("%i",(int)genotypeHost[n].G[0]);
//		printf("\n");
		if(error!=cudaSuccess){
			printf("genotype mem copy error %s\n",cudaGetErrorString(error));
			exit(0);
		}
		maxFit=0.0;
		for(j=0;j<3;j++)
			Phost[j]=0.0;
		for(i=0;i<popSize;i++){
			for(j=0;j<3;j++)
				Phost[j]+=genotypeHost[i].P[j];
			if(genotypeHost[i].fitness>maxFit)
				maxFit=genotypeHost[i].fitness;
		}
		makeReplacement<<<numBlocksPop,threadsPerBlockPop>>>(popSizeX,popSize,genotypeDeviceA,genotypeDeviceB,maxFit,mutationRate,rand(), rand(), rand(), rand());
		cudaThreadSynchronize();
		swap=genotypeDeviceA;
		genotypeDeviceA=genotypeDeviceB;
		genotypeDeviceB=swap;
		/*
		findReplacement<<<numBlocksRep,threadsPerBlockRep>>>(repSizeX,popSize,genotypeDevice,genotypeReplacementDevice,N,K,bitMask,NKTableDevice,mutationRate,rand(),rand(),rand(),rand());
		cudaThreadSynchronize();
		insertReplacement<<<numBlocksRep,threadsPerBlockRep>>>(repSizeX,popSize,rand()%popSize,genotypeDevice,genotypeReplacementDevice);
		cudaThreadSynchronize();
		*/
		float S=Phost[0]+Phost[1]+Phost[2];
		printf("update: %i maxFit:%f A:%f B:%f M:%f\n",update,maxFit,Phost[0]/S,Phost[1]/S,Phost[2]/S);
//		printf("%f %f %f - %f %f\n",genotypeHost[0].P[0],genotypeHost[0].P[1],genotypeHost[0].P[2],genotypeHost[0].G[0],genotypeHost[0].G[1]);
		fprintf(F1,"%i,%f,%f,%f\n",update,Phost[0]/S,Phost[1]/S,Phost[2]/S);
	}
	fclose(F1);
	return 0;
}

/// Reads the payoff matrix from the command line
void readPMfromCL(int argc, const char * argv[]){
	PM[0][0]=strtod(argv[5],NULL);
	PM[0][1]=strtod(argv[6],NULL);
	PM[0][2]=strtod(argv[7],NULL);
	PM[1][0]=strtod(argv[8],NULL);
	PM[1][1]=strtod(argv[9],NULL);
	PM[1][2]=strtod(argv[10],NULL);
	PM[2][0]=strtod(argv[11],NULL);
	PM[2][1]=strtod(argv[12],NULL);
	PM[2][2]=strtod(argv[13],NULL);

	FILE* fverify = fopen("verify.pm","w+t");
	//fprintf(fverify, "%i\t%i\t%i\n%i\t%i\t%i\n%i\t%i\t%i\n\n",PM[0][0],PM[0][1],PM[0][2],PM[1][0],PM[1][1],PM[1][2],PM[2][0],PM[2][1],PM[2][2]);
	fprintf(fverify, "%f\t%f\t%f\n%f\t%f\t%f\n%f\t%f\t%f",PM[0][0],PM[0][1],PM[0][2],PM[1][0],PM[1][1],PM[1][2],PM[2][0],PM[2][1],PM[2][2]);
	fclose(fverify);
}
