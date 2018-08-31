colpodiCUDA/Binomial.h                                                                              000644  000765  000024  00000000331 13333040601 017304  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _Binomial_h_
#define _Binomial_h_
#include "Seed.h"
#include "RandomGenerator.h"

class Binomial: public RandomGenerator{
public:
    __host__ __device__  virtual double GetBinomialRandomNumber();

};

#endif
                                                                                                                                                                                                                                                                                                       colpodiCUDA/DatesVector.h                                                                           000644  000765  000024  00000000176 13341267721 020021  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _DatesVector_h_
#define _DatesVector_h_

struct DatesVector{
    double* Path;
    int NumberOfFixingDate;
};

#endif
                                                                                                                                                                                                                                                                                                                                                                                                  colpodiCUDA/GPUData.h                                                                               000644  000765  000024  00000000150 13341267721 017013  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _GPUData_h_
#define _GPUData_h_

struct GPUData{
    int Threads, Streams, BlockSize;
};
#endif
                                                                                                                                                                                                                                                                                                                                                                                                                        colpodiCUDA/Gaussian.cu                                                                             000644  000765  000024  00000001572 13341304731 017522  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include <iostream>
#include <cmath>
#include "RandomGenerator.h"
#include "Gaussian.h"
#include "Seed.h"

__host__ __device__ double RandomGenerator::GetGaussianRandomNumber(){
  if(_Status==true){
      double u=this->GetUniformRandomNumber();
      double v=this->GetUniformRandomNumber();
      if(_BoxMullerWithReExtraction==false){
          if(u==0) return this->GetGaussianRandomNumber();
          _SavedRandomNumber=sqrt(-2.*log(u))*sin(2*M_PI*v);
          _Status=false;
          return sqrt(-2.*log(u))*cos(2*M_PI*v);
      }
      else{
            u=2*u-1;
            v=2*v-1;
            double r=u*u+v*v;
            if(r==0 || r>=1) return this->GetGaussianRandomNumber();
            _SavedRandomNumber=v*sqrt(-2.*log(r)/r);
            _Status=false;
            return u*sqrt(-2.*log(r)/r);
      }
  }
  else{
    _Status=true;
    return _SavedRandomNumber;
  }
};
                                                                                                                                      colpodiCUDA/Gaussian.h                                                                              000644  000765  000024  00000000453 13333040622 017334  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _Gaussian_h_
#define _Gaussian_h_
#include "Seed.h"
#include "RandomGenerator.h"

class Gaussian: public RandomGenerator{
public:
    __host__ __device__  virtual double GetGaussianRandomNumber();

private:
    double _SavedRandomNumber;
    bool _Status, _ReExtractionBoxMuller;
};

#endif
                                                                                                                                                                                                                     colpodiCUDA/KernelFunctions.cu                                                                      000644  000765  000024  00000005413 13341302530 021052  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include "KernelFunctions.h"

__host__ __device__ void TrueKernel(Seed* SeedVector, Statistics* PayOffs, int streams, MarketData MarketInput, OptionDataContainer OptionInput, SimulationParameters Parameters, int cont){

    RandomGenerator* Generator

    StocasticProcess* Process;
    if(Parameters.LogNormalProcess==0){
        Generator= new RandomGeneratorCombinedGaussian(SeedVector[cont], RE_EXTRACTION_BOX_MULLER);
        if(Parameters.EulerApprox==false)
          Process=new ExactLogNormalProcess(Generator);
        if(Parameters.EulerApprox==true)
          Process=new EulerLogNormalProcess(Generator);
    }
    else {
      cerr << "no known type process" << endl;
    }

    UnderlyingAnagraphy* Anagraphy=new UnderlyingAnagraphy(MarketInput);
    UnderlyingPrice* Price=new UnderlyingPrice(Anagraphy);

    MonteCarloPath* Path=new MonteCarloPath(Price, MarketInput.EquityInitialPrice, OptionInput.MaturityDate, OptionInput.NumberOfFixingDate, Parameters.EulerSubStep, Parameters.AntitheticVariable);

    OptionData OptionParameters;
    OptionParameters.MaturityDate=OptionInput.MaturityDate;
    OptionParameters.NumberOfFixingDate=OptionInput.NumberOfFixingDate;
    OptionParameters.OptionType=OptionInput.OptionType;

    Option* Option;
    if( OptionInput.OptionType==0){
        Option=new OptionForward(OptionParameters);
    }
    if( OptionInput.OptionType==1 || OptionInput.OptionType==2){
        OptionParameters.AdditionalParameters=new double[1];
        OptionParameters.AdditionalParameters[0]=OptionInput.StrikePrice;

        Option=new OptionPlainVanilla(OptionParameters);
    }

    if( OptionInput.OptionType==3){
        OptionParameters.AdditionalParameters=new double[3];
        OptionParameters.AdditionalParameters[0]=OptionInput.B;
        OptionParameters.AdditionalParameters[1]=OptionInput.K;
        OptionParameters.AdditionalParameters[2]=OptionInput.N;

        Option=new OptionAbsolutePerformanceBarrier(OptionParameters, MarketInput.Volatility, MarketInput.EquityInitialPrice);
    }

    MonteCarloPricer Pricer(Option, Path, Process, streams, Parameters.AntitheticVariable);

    PayOffs[cont].Reset();
    Pricer.ComputePrice(&PayOffs[cont]);

}

__global__ void Kernel(Seed* SeedVector, Statistics* PayOffs, int streams, MarketData MarketInput, OptionDataContainer OptionInput, SimulationParameters Parameters){

    int i = blockDim.x * blockIdx.x + threadIdx.x;

    TrueKernel(SeedVector,PayOffs, streams, MarketInput, OptionInput, Parameters, i);
};

__host__ void KernelSimulator(Seed* SeedVector, Statistics* PayOffs, int streams, MarketData MarketInput, OptionDataContainer OptionInput, SimulationParameters Parameters, int threads){

    for(int i=0; i<threads; i++) TrueKernel(SeedVector, PayOffs, streams, MarketInput, OptionInput, Parameters, i);

};
                                                                                                                                                                                                                                                     colpodiCUDA/KernelFunctions.h                                                                       000644  000765  000024  00000002164 13341267721 020706  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _KernelFunctions_cu_
#define _KernelFunctions_cu_

#define RE_EXTRACTION_BOX_MULLER false

#include "MonteCarloPricer.h"
#include "Statistics.h"
#include "RandomGenerator.h"
#include "RandomGeneratorCombined.h"
#include "Seed.h"
#include "MarketData.h"
#include "OptionData.h"
#include "SimulationParameters.h"
#include "Option.h"
#include "UnderlyingAnagraphy.h"
#include "UnderlyingPrice.h"

/*############################ Kernel Functions ############################*/

__host__ __device__ void TrueKernel(Seed* SeedVector, Statistics* PayOffs, int streams, MarketData MarketInput, OptionDataContainer OptionInput, SimulationParameters Parameters, int cont);

__global__ void Kernel(Seed* SeedVector, Statistics* PayOffs, int streams, MarketData MarketInput, OptionDataContainer OptionInput, SimulationParameters Parameters);

//## Funzione che gira su CPU che restituisce due vettori con sommme dei PayOff e dei PayOff quadrati. ##

__host__ void KernelSimulator(Seed* SeedVector, Statistics* PayOffs, int streams, MarketData MarketInput, OptionDataContainer OptionInput, SimulationParameters Parameters, int threads);

#endif
                                                                                                                                                                                                                                                                                                                                                                                                            colpodiCUDA/MCSimulator.cu                                                                          000644  000765  000024  00000031713 13341302460 020144  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include "MCSimulator.h"

using namespace std;

//## Funzione main #############################################################

int MCSimulator::main(){
    ofstream output;
    output.open(_OutputFile.c_str());

    //## Inizializzazione parametri di mercato e opzione. ##########################

    Reader(_InputFile, MarketInput, OptionInput, GPUInput, Parameters, CPUComparison, output);

    //## Allocazione di memoria. ###################################################

    sizeSeedVector = GPUInput.Threads * sizeof(Seed);
    sizeDevStVector = GPUInput.Threads * sizeof(Statistics);

    MemoryAllocationGPU(& PayOffsGPU,  & SeedVector, & _PayOffsGPU, & _SeedVector, sizeSeedVector, sizeDevStVector, GPUInput.Threads);

    if(CPUComparison==true)
        MemoryAllocationCPU(& PayOffsCPU, GPUInput.Threads);

    //## Costruzione vettore dei seed. #############################################

    GetSeeds(SeedVector, GPUInput.Threads, _Seed);

    cudaMemcpy(_SeedVector, SeedVector, sizeSeedVector, cudaMemcpyHostToDevice);

    //## Calcolo dei PayOff su GPU. ################################################

    cout<<"GPU simulation..."<<endl;

    gridSize = (GPUInput.Threads + GPUInput.BlockSize - 1) / GPUInput.BlockSize;

    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    Kernel<<<gridSize, GPUInput.BlockSize>>>(_SeedVector, _PayOffsGPU, GPUInput.Streams, MarketInput, OptionInput, Parameters);
    cudaEventRecord(stop);

    cudaMemcpy(PayOffsGPU, _PayOffsGPU, sizeDevStVector, cudaMemcpyDeviceToHost);

    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&GPUTime, start, stop);

    //## Calcolo dei PayOff su CPU. ################################################

    if(CPUComparison==true){
        cout<<"CPU simulation..."<<endl;

        startcpu = clock();
        KernelSimulator(SeedVector, PayOffsCPU, GPUInput.Streams, MarketInput, OptionInput, Parameters, GPUInput.Threads);
        CPUTime = (clock() - startcpu ) / (double) CLOCKS_PER_SEC;
    }

    //## Statistica... #####################################################

    for (int i=0; i<GPUInput.Threads; i++)
        FinalStatisticsGPU=FinalStatisticsGPU+PayOffsGPU[i];


    if(CPUComparison==true){
        for (int i=0; i<GPUInput.Threads; i++)
            FinalStatisticsCPU=FinalStatisticsCPU+PayOffsCPU[i];
    }

    //## Calcolo e stampa su file dei valori. ######################################

    cout<<endl<<"GPU values:"<<endl;
    output<<endl<<"GPU values:"<<endl;
    PrintActualizedPrice(FinalStatisticsGPU, OptionInput.MaturityDate, MarketInput.Drift, output);
    cout<<"Simulation time: "<<GPUTime<<" ms"<<endl<<endl;
    output<<"Simulation time: "<<GPUTime<<" ms"<<endl<<endl;

    if(CPUComparison==true){
        cout<<"CPU values:"<<endl;
        output<<"CPU values:"<<endl;
        PrintActualizedPrice(FinalStatisticsCPU, OptionInput.MaturityDate, MarketInput.Drift, output);
        cout<<"Simulation time: "<<CPUTime*1000<<" ms"<<endl<<endl;
        output<<"Simulation time: "<<CPUTime*1000<<" ms"<<endl<<endl;
    }

    //## Controllo #################################################################
    if(CPUComparison==true)
        PrintComparison(FinalStatisticsGPU, FinalStatisticsCPU, output);

    //## Liberazione memoria. ######################################################

    MemoryDeallocationGPU(PayOffsGPU, SeedVector, _PayOffsGPU, _SeedVector);
    if(CPUComparison==true)
        MemoryDeallocationCPU(PayOffsCPU);

    output.close();

    return 0;
}

//##############################################################################

//## Funzioni e utilities ######################################################

MCSimulator::MCSimulator(int Seed, string InputFile, string OutputFile){
    _InputFile=InputFile;
    _OutputFile=OutputFile;
    _Seed=Seed;
    GPUTime = 0;
}

void MCSimulator::GetSeeds(Seed* SeedVector, int THREADS, int seed){

    srand(seed);

    for(int i=0; i<THREADS; i++){
        do{
            SeedVector[i].S1=rand();
        }while(SeedVector[i].S1<128);
        do{
            SeedVector[i].S2=rand();
        }while(SeedVector[i].S2<128);
        do{
            SeedVector[i].S3=rand();
        }while(SeedVector[i].S3<128);
        SeedVector[i].S4=rand();
    }
};

void MCSimulator::MemoryAllocationCPU(Statistics** PayOffsCPU, int THREADS){
    *PayOffsCPU = new Statistics[THREADS];
};

void MCSimulator::MemoryAllocationGPU(Statistics** PayOffsGPU, Seed** SeedVector, Statistics** _PayOffsGPU, Seed** _SeedVector, size_t sizeSeedVector, size_t sizeDevStVector, int THREADS){
    cout<<"Memory allocation..."<<endl;
    *PayOffsGPU=new Statistics[THREADS];
    *SeedVector= new Seed[THREADS];

    cudaMalloc((void**)& *_PayOffsGPU, sizeDevStVector);
    cudaMalloc((void**)& *_SeedVector, sizeSeedVector);
};

void MCSimulator::MemoryDeallocationCPU(Statistics* PayOffsCPU){
    delete[] PayOffsCPU;
};

void MCSimulator::MemoryDeallocationGPU(Statistics* PayOffsGPU, Seed* SeedVector, Statistics* _PayOffsGPU, Seed* _SeedVector){
    delete[] PayOffsGPU;
    delete[] SeedVector;

    cudaFree(_PayOffsGPU);
    cudaFree(_SeedVector);

    cudaDeviceReset();
};

void MCSimulator::PrintActualizedPrice(Statistics Stat ,double MaturityDate, double Drift, ofstream& output){
    cout<<"Price: "<<Stat.GetMean()*exp(-MaturityDate*Drift) <<endl;
    cout<<"MC error: "<<Stat.GetStDev()<<endl;

    output<<"Price: "<<Stat.GetMean()*exp(-MaturityDate*Drift)<<endl;
    output<<"MC error: "<<Stat.GetStDev()<<endl;
};

void MCSimulator::PrintComparison(Statistics FinalStatisticsGPU, Statistics FinalStatisticsCPU, ofstream& output){
    GPUPrice=FinalStatisticsGPU.GetMean();
    CPUPrice=FinalStatisticsCPU.GetMean();
    GPUError=FinalStatisticsGPU.GetStDev();
    CPUError=FinalStatisticsCPU.GetStDev();

    if(GPUPrice==CPUPrice){
        cout<<"Prices are equivalent!"<<endl;
        output<<"Prices are equivalent!"<<endl;
    }

    else{
        cout<<"Prices are NOT equivalent!"<<endl;
        cout<<"Discrepancy: "<<GPUPrice-CPUPrice<<endl;
        output<<"Prices are NOT equivalent!"<<endl;
        output<<"Discrepancy: "<<GPUPrice-CPUPrice<<endl;
    }
    if(GPUError==CPUError){
        cout<<"Errors are equivalent!"<<endl;
        output<<"Errors are equivalent!"<<endl;
    }
    else{
        cout<<"Errors are NOT equivalent!"<<endl;
        cout<<"Discrepancy: "<<GPUError-CPUError<<endl;
        output<<"Errors are NOT equivalent!"<<endl;
        output<<"Discrepancy: "<<GPUError-CPUError<<endl;
    }
    cout<<"Performance gain: "<<CPUTime*1000/GPUTime<<" x"<<endl;
    output<<"Performance gain: "<<CPUTime*1000/GPUTime<<" x"<<endl;
};

void MCSimulator::Reader(string InputFile, MarketData &MarketInput, OptionDataContainer &OptionInput, GPUData &GPUInput, SimulationParameters &Parameters, bool &CPUComparison, ofstream& output){

    cout<<"Reading input file: "<<InputFile<<" ..."<<endl;
    fstream file;
    file.open(InputFile.c_str() , ios::in);

    if(file.fail()){
        cout<< "ERROR: input file not found! "<<  endl;
        output<< "ERROR: input file not found! "<<  endl;
        exit(1);
    }
    string temp, word;
    int Threads=0, Streams=0, BlockSize=0;
    int EulerApproximation=0, Antithetic=0;
    char OptionType[32] ProcessType[32];
    double Volatility=0, Drift=0;
    double InitialPrice=0, MaturityDate=0, StrikePrice=0;
    int DatesToSimulate=0, EulerSubStep=1;
    double ParamK=0, ParamB=0, ParamN=0;

    while (!file.eof()){
        file>>word;
        if (word=="THREADS") {
            file>> temp;
            Threads=atoi(temp.c_str());
        }
        if (word=="STREAMS"){
            file>> temp;
            Streams=atoi(temp.c_str());
        }
        if (word=="BLOCK_SIZE"){
            file>> temp;
            BlockSize=atoi(temp.c_str());
        }
        if (word=="EULER_APPROX"){
            file>> temp;
            EulerApproximation=atoi(temp.c_str());
        }
        if (word=="ANTITHETIC_VARIABLE"){
            file>> temp;
            Antithetic=atoi(temp.c_str());
        }
        if (word=="PROCESS_TYPE"){
            file>> temp;
            strcpy (ProcessType,temp.c_str());
        if (word=="OPTION_TYPE"){
            file>> temp;
            strcpy (OptionType,temp.c_str());
        }
        if (word=="VOLATILITY"){
            file>> temp;
            Volatility=atof(temp.c_str());
        }
        if (word=="DRIFT"){
            file>> temp;
            Drift=atof(temp.c_str());
        }
        if (word=="INITIAL_PRICE"){
            file>> temp;
            InitialPrice=atof(temp.c_str());
        }
        if (word=="MATURITY_DATE"){
            file>> temp;
            MaturityDate=atof(temp.c_str());
        }
        if (word=="DATES_TO_SIMULATE"){
            file>> temp;
            DatesToSimulate=atoi(temp.c_str());
        }
        if (word=="STRIKE_PRICE"){
            file>> temp;
            StrikePrice=atof(temp.c_str());
        }
        if (word=="PARAMETER_K"){
            file>> temp;
            ParamK=atof(temp.c_str());
        }
        if (word=="PARAMETER_N"){
            file>> temp;
            ParamN=atof(temp.c_str());
        }
        if (word=="PARAMETER_B"){
            file>> temp;
            ParamB=atof(temp.c_str());
        }
        if (word=="EULER_SUB_STEP"){
            file>> temp;
            EulerSubStep=atof(temp.c_str());
        }
        if (word=="CPU_COMPARISON"){
            file>> temp;
            CPUComparison=atoi(temp.c_str());
        }
    }

    file.close();

    GPUInput.Threads=Threads;
    GPUInput.Streams=Streams;
    GPUInput.BlockSize=BlockSize;

    bool AntitheticVariable=Antithetic;
    bool EulerBool=EulerApproximation;
    Parameters.EulerApprox=EulerBool;
    Parameters.EulerSubStep=EulerSubStep;
    Parameters.AntitheticVariable=AntitheticVariable;

    MarketInput.Volatility=Volatility;
    MarketInput.Drift=Drift;
    MarketInput.EquityInitialPrice=InitialPrice;

    if(EulerBool==false)
        EulerSubStep=1;

    OptionInput.MaturityDate=MaturityDate;
    OptionInput.NumberOfFixingDate=DatesToSimulate,
    OptionInput.StrikePrice=StrikePrice;

    if(strcmp(ProcessType,"LOGNORMAL")==0)
        Parameters.ProcessType=0;

    if(strcmp(OptionType,"FORWARD")==0)
        OptionInput.OptionType=0;

    if(strcmp(OptionType,"PLAIN_VANILLA_CALL")==0)
        OptionInput.OptionType=1;

    if(strcmp(OptionType,"PLAIN_VANILLA_PUT")==0)
        OptionInput.OptionType=2;

    if(strcmp(OptionType,"ABSOLUTE_PERFORMANCE_BARRIER")==0)
        OptionInput.OptionType=3;

    OptionInput.B=ParamB;
    OptionInput.N=ParamN;
    OptionInput.K=ParamK;

    output<<"Simulation parameters:"<<endl;
    output<<"Input file: "<<InputFile<<endl;
    output<<"Number of blocks requested: "<< (GPUInput.Threads + GPUInput.BlockSize - 1) / GPUInput.BlockSize<<endl;
    output<<"Thread per block requested: "<< GPUInput.BlockSize <<endl;
    output<<"CPU comparison: "<<CPUComparison<<endl;

}

//## Test di non-regressione ###################################################

int MCSimulator::RegressionTest(){

    //## Opzione di benchmark: Plain Vanilla Call coi seguenti parametri: ######

    MarketInput.Volatility=0.1;
    MarketInput.Drift=0.001;
    MarketInput.EquityInitialPrice=100.;

    OptionInput.MaturityDate=1.;
    OptionInput.NumberOfFixingDate=1;
    OptionInput.StrikePrice=100.;
    OptionInput.OptionType=1;

    GPUInput.Threads=5120;
    GPUInput.Streams=5000;
    GPUInput.BlockSize=512;

    Parameters.EulerApprox=0;
    Parameters.AntitheticVariable=0;
    Parameters.EulerSubStep=1;

    sizeSeedVector = GPUInput.Threads * sizeof(Seed);
    sizeDevStVector = GPUInput.Threads * sizeof(Statistics);
    MemoryAllocationGPU(& PayOffsGPU,  & SeedVector, & _PayOffsGPU, & _SeedVector, sizeSeedVector, sizeDevStVector, GPUInput.Threads);

    GetSeeds(SeedVector, GPUInput.Threads, _Seed);
    cudaMemcpy(_SeedVector, SeedVector, sizeSeedVector, cudaMemcpyHostToDevice);

    cout<<"Simulating test..."<<endl;

    gridSize = (GPUInput.Threads + GPUInput.BlockSize - 1) / GPUInput.BlockSize;
    Kernel<<<gridSize, GPUInput.BlockSize>>>(_SeedVector, _PayOffsGPU, GPUInput.Streams, MarketInput, OptionInput, Parameters);

    cudaMemcpy(PayOffsGPU, _PayOffsGPU, sizeDevStVector, cudaMemcpyDeviceToHost);

    for (int i=0; i<GPUInput.Threads; i++)
        FinalStatisticsGPU=FinalStatisticsGPU+PayOffsGPU[i];

    if(FinalStatisticsGPU.GetMean()==4.0411858633024114)
        cout<<"PASSED!"<<endl;
    else{
        cout<<"FAILED!: "<<endl;
        cout<<"Expected price: "<<4.0411858633024114*exp(OptionInput.NumberOfFixingDate*MarketInput.Drift)<<endl;
        cout<<"Obtained price: "<<FinalStatisticsGPU.GetMean()*exp(OptionInput.NumberOfFixingDate*MarketInput.Drift)<<endl;

    }
    if(FinalStatisticsGPU.GetStDev()==0.0012322640294403595)
        cout<<"PASSED!"<<endl;
    else{
        cout<<"FAILED!: "<<endl;
        cout<<"Expected MC error: "<<0.0012322640294403595<<endl;
        cout<<"Obtained MC error: "<<FinalStatisticsGPU.GetStDev()<<endl;
    }

    MemoryDeallocationGPU(PayOffsGPU, SeedVector, _PayOffsGPU, _SeedVector);

    return 0;
};
                                                     colpodiCUDA/MCSimulator.h                                                                           000644  000765  000024  00000003631 13341267721 017774  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include <iostream>
#include <cstdio>
#include <ctime>
#include <fstream>
#include "Statistics.h"
#include "Seed.h"
#include "MarketData.h"
#include "OptionData.h"
#include "GPUData.h"
#include "SimulationParameters.h"
#include "KernelFunctions.h"

using namespace std;

class MCSimulator{
private:
    string _InputFile, _OutputFile;
    int _Seed;
    bool CPUComparison;

    MarketData MarketInput;
    OptionDataContainer OptionInput;
    SimulationParameters Parameters;
    GPUData GPUInput;

    Statistics* PayOffsGPU;
    Statistics* PayOffsCPU;
    Seed *SeedVector;
    Statistics* _PayOffsGPU;
    Seed *_SeedVector;

    size_t sizeSeedVector;
    size_t sizeDevStVector;

    int gridSize;
    cudaEvent_t start, stop;
    float GPUTime;
    double CPUTime;
    clock_t startcpu;

    Statistics FinalStatisticsGPU;
    Statistics FinalStatisticsCPU;

    double GPUPrice;
    double CPUPrice;
    double GPUError;
    double CPUError;

    void GetSeeds(Seed* SeedVector, int THREADS, int seed);
    void MemoryAllocationCPU(Statistics** PayOffsCPU, int THREADS);
    void MemoryAllocationGPU(Statistics** PayOffsGPU, Seed** SeedVector, Statistics** _PayOffsGPU, Seed** _SeedVector, size_t sizeSeedVector, size_t sizeDevStVector, int THREADS);
    void MemoryDeallocationGPU(Statistics* PayOffsGPU, Seed* SeedVector, Statistics* _PayOffsGPU, Seed* _SeedVector);
    void MemoryDeallocationCPU(Statistics* PayOffsCPU);
    void PrintActualizedPrice(Statistics Stat ,double MaturityDate, double Drift, ofstream& output);
    void PrintComparison(Statistics FinalStatisticsGPU, Statistics FinalStatisticsCPU, ofstream& output);
    void Reader(string InputFile, MarketData &MarketInput, OptionDataContainer &OptionInput, GPUData &GPUInput, SimulationParameters &Parameters, bool &CPUComparison, ofstream& output);

public:
    MCSimulator(int Seed, string InputFile, string OutputFile);
    int main();
    int RegressionTest();
};
                                                                                                       colpodiCUDA/MarketData.h                                                                            000644  000765  000024  00000000177 13341267721 017614  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _MarketData_h_
#define _MarketData_h_

struct MarketData{
    double Volatility, Drift, EquityInitialPrice;
};

#endif
                                                                                                                                                                                                                                                                                                                                                                                                 colpodiCUDA/MonteCarloPath.cu                                                                       000644  000765  000024  00000003706 13341267721 020640  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include "MonteCarloPath.h"

__host__ __device__  MonteCarloPath::MonteCarloPath(UnderlyingPrice* Price, double EquityInitialPrice, double MaturityDate, int NumberOfFixingDate, int EulerSubStep, bool AntitheticVariable){
    _MaturityDate=MaturityDate;
    _NumberOfFixingDate=NumberOfFixingDate;
    _UnderlyingPath = new double[NumberOfFixingDate];
    _EulerSubStep = EulerSubStep;
    _Step=Price;
    _EquityInitialPrice=EquityInitialPrice;
    _AntitheticVariable=AntitheticVariable;
    if(AntitheticVariable==true)
        _RandomNumbers= new double[NumberOfFixingDate*EulerSubStep];
};

__host__ __device__  MonteCarloPath::~MonteCarloPath(){
    delete[] _UnderlyingPath;
    if(_AntitheticVariable==true)
        delete[] _RandomNumbers;
};

__host__ __device__  DatesVector MonteCarloPath::GetPath(StocasticProcess* Process){
    double TimeStep =  _MaturityDate / (_NumberOfFixingDate*_EulerSubStep);
    _Step->Price=_EquityInitialPrice;

    for(int i=0; i<_NumberOfFixingDate; i++){
        for(int j=0; j<_EulerSubStep; j++){
            double rnd=Process->GetRandomNumber();
            Process->Step(_Step, TimeStep, rnd);
            if(_AntitheticVariable==true)
                _RandomNumbers[i*_EulerSubStep+j]=rnd;
        }
        _UnderlyingPath[i]=_Step->Price;
    }

    DatesVector Dates;
    Dates.Path=_UnderlyingPath;
    Dates.NumberOfFixingDate=_NumberOfFixingDate;
    return Dates;
};

__host__ __device__  DatesVector MonteCarloPath::GetAntitheticPath(StocasticProcess* Process){
    double TimeStep =  _MaturityDate / (_NumberOfFixingDate*_EulerSubStep);
    _Step->Price=_EquityInitialPrice;
    for(int i=0; i<_NumberOfFixingDate; i++){
        for(int j=0; j<_EulerSubStep; j++){
            Process->Step(_Step, TimeStep, -1.*_RandomNumbers[i*_EulerSubStep+j]);
        }
        _UnderlyingPath[i]=_Step->Price;
    }

    DatesVector Dates;
    Dates.Path=_UnderlyingPath;
    Dates.NumberOfFixingDate=_NumberOfFixingDate;
    return Dates;
}
                                                          colpodiCUDA/MonteCarloPath.h                                                                        000644  000765  000024  00000002004 13341267721 020446  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         /*#######################################################
# Classe che implementa la simulazione dell'evoluzione  #
# del prezzo del sottostante (GetPath)                  #
#######################################################*/

#ifndef _MonteCarloPath_h_
#define _MonteCarloPath_h_

#include "StochasticProcess.h"
#include "MarketData.h"
#include "DatesVector.h"
#include "UnderlyingPrice.h"

class MonteCarloPath{
public:
    __host__ __device__ MonteCarloPath(UnderlyingPrice* , double EquityInitialPrice, double MaturityDate, int NumberOfFixingDate, int EulerSubStep, bool AntitheticVariable);
    __host__ __device__ ~MonteCarloPath();
    __host__ __device__ DatesVector GetPath(StocasticProcess*);
    __host__ __device__ DatesVector GetAntitheticPath(StocasticProcess*);
private:
    double* _UnderlyingPath;
    double* _RandomNumbers;
    UnderlyingPrice* _Step;
    double _MaturityDate;
    double _EquityInitialPrice;
    int _NumberOfFixingDate;
    int _EulerSubStep;
    bool _AntitheticVariable;
};

#endif
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            colpodiCUDA/MonteCarloPricer.cu                                                                     000644  000765  000024  00000001511 13341267721 021160  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include "MonteCarloPricer.h"

__device__ __host__ MonteCarloPricer::MonteCarloPricer(Option* Option, MonteCarloPath* Path, StocasticProcess* Process, int NStreams, bool AntitheticVariable){
    _NStreams=NStreams;
    _Option=Option;
    _Path=Path;
    _Process=Process;
    _AntitheticVariable=AntitheticVariable;
};

//## Metodo per il calcolo delle somme semplici e quadrate dei PayOff simulati in uno stream. ##

__device__ __host__ void MonteCarloPricer::ComputePrice(Statistics* PayOffs){
    for(int j=0; j<_NStreams; j++){
        DatesVector Dates=_Path->GetPath(_Process);
        PayOffs->AddValue(_Option->GetPayOff(Dates));
        if(_AntitheticVariable==true){
            DatesVector AntitheticDates=_Path->GetAntitheticPath(_Process);
            PayOffs->AddValue(_Option->GetPayOff(AntitheticDates));
        }
    }
};
                                                                                                                                                                                       colpodiCUDA/MonteCarloPricer.h                                                                      000644  000765  000024  00000001410 13341267721 020776  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         /*#####################################################
# Classe che restituisce la somma e la somma quadrata #
# dei Pay Off calcolati in uno stream (ComputePrice). #
#####################################################*/

#ifndef _MonteCarloPricer_h_
#define _MonteCarloPricer_h_

#include "Option.h"
#include "Statistics.h"
#include "MonteCarloPath.h"
#include "StochasticProcess.h"
#include "DatesVector.h"

class MonteCarloPricer{
public:
    __device__ __host__ MonteCarloPricer(Option*, MonteCarloPath*, StocasticProcess*, int Nstreams, bool AntitheticVariable);
    __device__ __host__ void ComputePrice(Statistics*);
private:
    Option* _Option;
    MonteCarloPath* _Path;
    StocasticProcess* _Process;
    int _NStreams;
    bool _AntitheticVariable;
};

#endif
                                                                                                                                                                                                                                                        colpodiCUDA/Option.cu                                                                               000644  000765  000024  00000004205 13341267721 017223  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include <cmath>
#include "Option.h"

__host__ __device__ Option::Option(OptionData OptionParameters){
    _OptionParameters = OptionParameters;
};

__host__ __device__ OptionForward::OptionForward(OptionData OptionParameters):
    Option(OptionParameters){};

__host__ __device__ double OptionForward::GetPayOff(DatesVector Dates){
    double* Path=Dates.Path;
    int NumberOfFixingDate=Dates.NumberOfFixingDate;

    return Path[NumberOfFixingDate-1];
};

__host__ __device__ OptionPlainVanilla::OptionPlainVanilla(OptionData OptionParameters):
    Option(OptionParameters){};

__host__ __device__  double OptionPlainVanilla::GetPayOff(DatesVector Dates){
    double* Path=Dates.Path;
    int NumberOfFixingDate=Dates.NumberOfFixingDate;

    double StrikePrice=_OptionParameters.AdditionalParameters[0];

    double PayOff=0;
    if( _OptionParameters.OptionType==1)
      PayOff=Path[NumberOfFixingDate-1]-StrikePrice;
    if( _OptionParameters.OptionType==2)
      PayOff=StrikePrice-Path[NumberOfFixingDate-1];

    if(PayOff>0) return PayOff;
    else return 0.;
};

__host__ __device__ OptionAbsolutePerformanceBarrier::OptionAbsolutePerformanceBarrier(OptionData OptionParameters, double Volatility, double EquityInitialPrice):
    Option(OptionParameters){
        _Volatility=Volatility;
        _EquityInitialPrice=EquityInitialPrice;
    };

__host__ __device__  double OptionAbsolutePerformanceBarrier::GetPayOff(DatesVector Dates){
    double* Path=Dates.Path;
    int NumberOfFixingDate=Dates.NumberOfFixingDate;

    double N=_OptionParameters.AdditionalParameters[2];
    double B=_OptionParameters.AdditionalParameters[0];
    double K=_OptionParameters.AdditionalParameters[1];

    double SumP=0;
    double TStep= _OptionParameters.MaturityDate / NumberOfFixingDate;
    double Norm=1./sqrt(TStep);

    if( abs( Norm*log(Path[0]/_EquityInitialPrice)) > B * _Volatility )
        SumP=SumP+1.;

    for(int i=0; i<NumberOfFixingDate-1; i++){
        if( abs( Norm*log(Path[i+1]/Path[i]) ) > B * _Volatility )
            SumP=SumP+1.;
    }

    if( SumP/NumberOfFixingDate-K > 0 )
        return N*(SumP/NumberOfFixingDate-K);
    else
        return 0;
};
                                                                                                                                                                                                                                                                                                                                                                                           colpodiCUDA/Option.h                                                                                000644  000765  000024  00000002033 13341267721 017040  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         /*##########################################
# Tipi di Payoff utilizzabili implementati #
# nella libreria.                          #
##########################################*/

#ifndef _Option_h_
#define _Option_h_
#include "OptionData.h"
#include "DatesVector.h"

class Option{
public:
    __device__ __host__ Option(OptionData);
    __device__ __host__  virtual double GetPayOff(DatesVector)=0;
protected:
    OptionData _OptionParameters;
};

class OptionForward: public Option{
public:
    __device__ __host__ OptionForward(OptionData);
    __device__ __host__  double GetPayOff(DatesVector);
};

class OptionPlainVanilla: public Option{
public:
    __device__ __host__ OptionPlainVanilla(OptionData);
    __device__ __host__  double GetPayOff(DatesVector);
};

class OptionAbsolutePerformanceBarrier: public Option{
public:
    __device__ __host__ OptionAbsolutePerformanceBarrier(OptionData, double, double);
    __device__ __host__  double GetPayOff(DatesVector);
private:
    double _EquityInitialPrice;
    double _Volatility;
};

#endif
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     colpodiCUDA/OptionData.h                                                                            000644  000765  000024  00000000515 13341267721 017635  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _OptionData_h_
#define _OptionData_h_

struct OptionDataContainer{
    double MaturityDate;
    int NumberOfFixingDate;
    double StrikePrice;
    int OptionType;
    double B, N, K;
};

struct OptionData{
    double MaturityDate;
    int NumberOfFixingDate;
    int OptionType;
    double* AdditionalParameters;
};

#endif
                                                                                                                                                                                   colpodiCUDA/README.md                                                                               000644  000765  000024  00000002046 13341267721 016702  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         > ```
>            _                 _ _  _____ _    _ _____          
>           | |               | (_)/ ____| |  | |  __ \   /\    
>   ___ ___ | |_ __   ___   __| |_| |    | |  | | |  | | /  \   
>  / __/ _ \| | '_ \ / _ \ / _` | | |    | |  | | |  | |/ /\ \  
> | (_| (_) | | |_) | (_) | (_| | | |____| |__| | |__| / ____ \ 
>  \___\___/|_| .__/ \___/ \__,_|_|\_____|\____/|_____/_/    \_\
>             | |                                               
>             |_|                                               
> ```  
    
----- LIBRERIA PER OPTION PRICING ----- PRODUZIONE ARTIGIANALE -----

PER USARE IL PROGRAMMA:
Il makefile crea il programma eseguibile chiamato "pricer" per la simulazione Monte Carlo e un test di non regressione chiamato "test", compilabile col comando "make test".
Il file contenente i dati di input viene specificato al compilatore nel file main.cu (di default è impostato il file "input.conf" nella cartella "DATA").
Si veda il file "input.conf" di esempio per i parametri da utilizzare.

Ultimo aggiornamento: sa dio
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          colpodiCUDA/RandomGenerator.cu                                                                      000644  000765  000024  00000000340 13333040715 021027  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include <iostream>
#include <cmath>
#include "RandomGenerator.h"
//#include "RandomGeneratorCombined.h"
#include "Seed.h"

__host__ __device__ double RandomGenerator::GetStocasticVariable(){
  return _StocasticVariable;
};
                                                                                                                                                                                                                                                                                                colpodiCUDA/RandomGenerator.h                                                                       000644  000765  000024  00000001241 13341304122 020642  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         /*########################################################################
# Classe per la generazione di numeri casuali distribuiti                #
# uniformemente (GetUniformRandomNumber) o gaussianamente (GetGaussianRandomNumber).       #
########################################################################*/

#ifndef _RandomGenerator_h_
#define _RandomGenerator_h_

#include "Seed.h"

class RandomGenerator{
public:
    __host__ __device__  virtual double GetUniformRandomNumber()=0;
    __host__ __device__  virtual double GetStocasticVariable();
    __host__ __device__  virtual void SetStocasticVariable();
protected:
    double _StocasticVariable;
};

#endif
                                                                                                                                                                                                                                                                                                                                                               colpodiCUDA/RandomGeneratorCombined.cu                                                              000644  000765  000024  00000001750 13324405755 022507  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include <iostream>
#include <cmath>
#include "RandomGenerator.h"
#include "RandomGeneratorCombined.h"
#include "Seed.h"

__host__ __device__  RandomGeneratorCombined::RandomGeneratorCombined(Seed S, bool ReExtractionBoxMuller){
    _Seed=S;
    _ReExtractionBoxMuller=ReExtractionBoxMuller;
    _Status=true;
};

__host__ __device__  unsigned int RandomGeneratorCombined::LCGStep(unsigned int &seed, unsigned int a, unsigned long b){
	return seed=(a*seed+b)%UINT_MAX;

};

__host__ __device__  unsigned int RandomGeneratorCombined::TausStep(unsigned int &seed, unsigned int K1, unsigned int K2, unsigned int K3, unsigned long M){
	unsigned int b=(((seed<<K1)^seed)>>K2);
  return seed=(((seed&M)<<K3)^b);

};

__host__ __device__  double RandomGeneratorCombined::GetUniformRandomNumber(){
    return 2.3283064365387e-10*(TausStep(_Seed.S1, 13, 19, 12, 4294967294UL)^TausStep(_Seed.S2, 2, 25, 4, 4294967288UL)^TausStep(_Seed.S3, 3, 11, 17, 4294967280UL)^LCGStep(_Seed.S4, 1664525, 1013904223UL));
};
                        colpodiCUDA/RandomGeneratorCombined.h                                                               000644  000765  000024  00000001251 13333041214 022305  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _RandomGeneratorCombined_h_
#define _RandomGeneratorCombined_h_

class RandomGeneratorCombined: public RandomGenerator{
public:
    __host__ __device__  RandomGeneratorCombined(Seed, bool);
    __host__ __device__  unsigned int LCGStep(unsigned int &, unsigned int , unsigned long );
    __host__ __device__  unsigned int TausStep(unsigned int &, unsigned int , unsigned int , unsigned int , unsigned long );
    __host__ __device__  double GetUniformRandomNumber();

private:
    Seed _Seed;
};

#endif

//A QUESTO PUNTO VA FATTO UN FIGLIO DI RANDOMGENERATORCOMBINED E GAUSSIAN CHE ABBIA
//COME METODO UNA COSA CHE COMBINA GetUniformRandomNumber E GetGaussianRandomNumber
                                                                                                                                                                                                                                                                                                                                                       colpodiCUDA/RandomGeneratorCombinedGaussian.cu                                                      000644  000765  000024  00000000352 13341304777 024200  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include <iostream>
#include <cmath>
#include "RandomGeneratorCombinedGaussian.h"
#include "Seed.h"

__host__ __device__ RandomGeneratorCombinedGaussian::SetStocasticVariable(){
  _StocasticVariable=this->GetGaussianRandomNumber();
}
                                                                                                                                                                                                                                                                                      colpodiCUDA/RandomGeneratorCombinedGaussian.h                                                       000644  000765  000024  00000000612 13341305447 024012  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _RandomGeneratorCombinedGaussian_h_
#define _RandomGeneratorCombinedGaussian_h_

#include  "RandomGeneratorCombined.h"
#include  "Gaussian.h"

class RandomGeneratorCombinedGaussian: public RandomGeneratorCombined, public Gaussian{
public:
    __host__ __device__  RandomGeneratorCombinedGaussian();
    __host__ __device__  SetStocasticVariable();


private:
    Seed _Seed;
};

#endif
                                                                                                                      colpodiCUDA/RegressionTest.cu                                                                       000644  000765  000024  00000000450 13341267721 020731  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #define SEED 1889

// ## Non modificare SEED!######################################################

#include "MCSimulator.h"

int main(){

    //## implementazione: vedi file MCSimulator.cu #############################
    MCSimulator MCSim(SEED, "", "");
    return MCSim.RegressionTest();

}
                                                                                                                                                                                                                        colpodiCUDA/Seed.h                                                                                  000644  000765  000024  00000000134 13341267721 016450  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _Seed_h_
#define _Seed_h_

struct Seed{
    unsigned int S1, S2, S3, S4;
};

#endif
                                                                                                                                                                                                                                                                                                                                                                                                                                    colpodiCUDA/SimulationParameters.h                                                                  000644  000765  000024  00000000311 13341302507 021725  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _SimulationParameters_h_
#define _SimulationParameters_h_

struct SimulationParameters{
    bool EulerApprox;
    bool AntitheticVariable;
    int ProcessType;
    int EulerSubStep;
};

#endif
                                                                                                                                                                                                                                                                                                                       colpodiCUDA/Statistics.cu                                                                           000644  000765  000024  00000002126 13341267721 020105  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include "Statistics.h"
#include <cmath>

using namespace std;

__host__ __device__ Statistics::Statistics(){
	_Cumulant=0;
	_Cumulant2=0;
	_Cont=0;
};

__host__ __device__ void Statistics::AddValue(double value){
	_Cumulant+=value;
	_Cumulant2+=value*value;
	_Cont=_Cont+1;
};

__host__ __device__ double Statistics::GetCumulant(){
	return _Cumulant;
};

__host__ __device__ double Statistics::GetCumulant2(){
	return _Cumulant2;
};

__host__ __device__ int Statistics::GetCont(){
	return _Cont;
};

__host__ __device__ void Statistics::Reset(){
	_Cumulant=0;
	_Cumulant2=0;
	_Cont=0;
};

__host__ double Statistics::GetMean(){
	return this->GetCumulant()/this->GetCont();
};

__host__ double Statistics::GetStDev(){
	int N=this->GetCont();
	return sqrt(abs(this->GetCumulant2()/N-this->GetMean()*this->GetMean())/N);
};

__host__ Statistics Statistics::operator+(const Statistics& statistic){
	Statistics _statistic;
	_statistic._Cumulant=this->_Cumulant+statistic._Cumulant;
	_statistic._Cumulant2=this->_Cumulant2+statistic._Cumulant2;
	_statistic._Cont=this->_Cont+statistic._Cont;
	return _statistic;
};
                                                                                                                                                                                                                                                                                                                                                                                                                                          colpodiCUDA/Statistics.h                                                                            000644  000765  000024  00000001554 13341267721 017731  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         /*#############################################
# Classe che implementa i metodi per ottenere #
# prezzo dell'opzione mediato su tutti gli    #
# scenari montecarlo (GetPrice) e l'errore    #
# montecarlo associato (GetMCError).          #
#############################################*/

#ifndef _Statistics_h_
#define _Statistics_h_

class Statistics{
public:
	__host__ __device__ Statistics();
	__host__ __device__ void AddValue(double value);
	__host__ __device__ double GetCumulant();
  __host__ __device__ double GetCumulant2();
	__host__ __device__ int GetCont();
	__host__ __device__ void Reset();
	__host__ double GetMean();
	__host__ double GetStDev();
	__host__ Statistics operator+(const Statistics& statistic);

private:
	double _Cumulant;
	double _Cumulant2;
	int _Cont;  //contatore per la lunghezza del vettore per ogni thread. Cont=Streams/Threads
};

#endif
                                                                                                                                                    colpodiCUDA/StochasticProcess.cu                                                                    000644  000765  000024  00000001643 13341301617 021412  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #include <cmath>
#include "StochasticProcess.h"

__host__ __device__ ExactLogNormalProcess::ExactLogNormalProcess(RandomGenerator* Generator){
    _Generator=Generator;
};

__host__ __device__ void ExactLogNormalProcess::Step(UnderlyingPrice * Step, double TimeStep){
    double Drift=Step->Anagraphy->Drift;
    double Volatility=Step->Anagraphy->Volatility;
    Step->Price=Step->Price*exp((Drift - (Volatility*Volatility)/2)*TimeStep + Volatility*sqrt(TimeStep)*_Generator->GetStocastiVariable());

};


__host__ __device__  EulerLogNormalProcess::EulerLogNormalProcess(RandomGenerator* Generator){
    _Generator=Generator;
};

__host__ __device__ void EulerLogNormalProcess::Step(UnderlyingPrice * Step, double TimeStep){
    double Drift=Step->Anagraphy->Drift;
    double Volatility=Step->Anagraphy->Volatility;
    Step->Price=Step->Price*(1.+Drift*TimeStep+Volatility*sqrt(TimeStep)*_Generator->GetStocastiVariable());
};
                                                                                             colpodiCUDA/StochasticProcess.h                                                                     000644  000765  000024  00000002302 13341300713 021217  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         /*####################################################################################################
# Classi che implementano i metodi per simulare gli step temporali dell'evoluzione del prezzo del    #
# sottostante secondo processo esatto (ExactLogNormalProcess) o approssimato (EulerLogNormalProcess) #
####################################################################################################*/

#ifndef _StochasticProcess_h_
#define _StochasticProcess_h_

#include "RandomGenerator.h"
#include "MarketData.h"
#include "UnderlyingPrice.h"

class StocasticProcess{
public:
    __host__ __device__ virtual void Step(UnderlyingPrice*, double TimeStep)=0;
    __host__ __device__ virtual double GetRandomNumber()=0;
protected:
    RandomGenerator* _Generator;
};

class ExactLogNormalProcess: public StocasticProcess{
public:
    __host__ __device__ ExactLogNormalProcess(RandomGenerator* Generator);
    __host__ __device__ void Step(UnderlyingPrice * Step, double TimeStep);
};

class EulerLogNormalProcess: public StocasticProcess{
public:
    __host__ __device__ EulerLogNormalProcess(RandomGenerator* Generator);
    __host__ __device__ void Step(UnderlyingPrice * Step, double TimeStep);
};

#endif
                                                                                                                                                                                                                                                                                                                              colpodiCUDA/UnderlyingAnagraphy.h                                                                   000644  000765  000024  00000000502 13341267721 021542  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _UnderlyingAnagraphy_h_
#define _UnderlyingAnagraphy_h_

#include "MarketData.h"

struct UnderlyingAnagraphy{
    double Volatility;
    double Drift;
    __host__ __device__ UnderlyingAnagraphy(MarketData MarketInput){
        Volatility=MarketInput.Volatility;
        Drift=MarketInput.Drift;
    };
};

#endif
                                                                                                                                                                                              colpodiCUDA/UnderlyingPrice.h                                                                       000644  000765  000024  00000000453 13341267721 020677  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         #ifndef _UnderlyingPrice_h_
#define _UnderlyingPrice_h_

#include "UnderlyingAnagraphy.h"

struct UnderlyingPrice{
    double Price;
    UnderlyingAnagraphy* Anagraphy;
    __host__ __device__ UnderlyingPrice(UnderlyingAnagraphy* AnagraphyInput){
        Anagraphy=AnagraphyInput;
    };
};

#endif
                                                                                                                                                                                                                     colpodiCUDA/input.conf                                                                              000644  000765  000024  00000001663 13341302303 017417  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         INPUT DATA OF MONTE CARLO SIMULATION

###################################

Number of total thread:

THREADS 5120

Threads per block (recommended 512):

BLOCK_SIZE 512

Number of Monte Carlo simulations for each thread:

STREAMS 5000

########### Simulation parameters:

CPU_COMPARISON 0

ANTITHETIC_VARIABLE 0

Process Type ("LOGNORMAL" )

PROCESS_TYPE LOGNORMAL

Euler approximation (bool: 0 exact - 1 approx)

EULER_APPROX 0

EULER_SUB_STEP 1

Option Type ("FORWARD" - "PLAIN_VANILLA_CALL" - "PLAIN_VANILLA_PUT" - "ABSOLUTE_PERFORMANCE_BARRIER" )

OPTION_TYPE PLAIN_VANILLA_CALL
############# Market data:

VOLATILITY 0.3
DRIFT 0.04

# Equity Initial Price:
INITIAL_PRICE 100

############## Option data:

Maturity Date:

MATURITY_DATE 1

Number Of Dates To Simulate:

DATES_TO_SIMULATE 1

strike price (use with plain vanilla)

STRIKE_PRICE 100

Other parameters (use with absolute performance)

PARAMETER_N 1

PARAMETER_B 0.25
PARAMETER_K 0.1
                                                                             colpodiCUDA/main.cu                                                                                 000644  000765  000024  00000003322 13341267721 016676  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         /*##############################################################################################################################################################
# Pricer MonteCarlo di opzioni la cui dinamica e' determinata da processi lognormali esatti o approssimati.                                                    #
#                                                                                                                                                              #
# Usage: ./pricer                                                                                                                                              #
# Speficicare: Dati di input del processo (MarketData), Dati di input dell'opzione (OptionData), tipo di opzione (guarda in Option.h per quelle implementate), #
#             tipo di processo (guarda in StocasticProcess.h per quelli implementati). Vedi file input.conf in DATA                                            #
#                                                                                                                                                              #
# Output: Prezzo stimato secondo il Pay Off specificato e corrispondente errore MonteCarlo.                                                                    #
##############################################################################################################################################################*/

#define SEED 1995
#define INPUT_FILE "DATA/input.conf"
#define OUTPUT_FILE "DATA/output.dat"

#include "MCSimulator.h"

int main(){

    //## implementazione: vedi file MCSimulator.cu #############################
    MCSimulator MCSim(SEED, INPUT_FILE, OUTPUT_FILE);
    return MCSim.main();

}
                                                                                                                                                                                                                                                                                                              colpodiCUDA/makefile                                                                                000644  000765  000024  00000005422 13341305423 017114  0                                                                                                    ustar 00michelecaresana                 staff                           000000  000000                                                                                                                                                                         pricer: main.o MCSimulator.o KernelFunctions.o RandomGenerator.o RandomGeneratorCombined.o RandomGeneratorCombinedGaussian.o StochasticProcess.o MonteCarloPath.o Option.o MonteCarloPricer.o Statistics.o
	nvcc -gencode arch=compute_20,code=sm_20 main.o MCSimulator.o KernelFunctions.o RandomGenerator.o RandomGeneratorCombined.o RandomGeneratorCombinedGaussian.o StochasticProcess.o MonteCarloPath.o Option.o MonteCarloPricer.o Statistics.o -o pricer

test: RegressionTest.o MCSimulator.o KernelFunctions.o RandomGenerator.o RandomGeneratorCombined.o RandomGeneratorCombinedGaussian.o StochasticProcess.o MonteCarloPath.o Option.o MonteCarloPricer.o Statistics.o
	nvcc -gencode arch=compute_20,code=sm_20 RegressionTest.o MCSimulator.o KernelFunctions.o RandomGenerator.o RandomGeneratorCombined.o RandomGeneratorCombinedGaussian.o StochasticProcess.o MonteCarloPath.o Option.o MonteCarloPricer.o Statistics.o -o test

RegressionTest.o: RegressionTest.cu
	nvcc -gencode arch=compute_20,code=sm_20 -dc RegressionTest.cu -o RegressionTest.o -I.

main.o: main.cu
	nvcc -gencode arch=compute_20,code=sm_20 -dc main.cu -o main.o -I.

MCSimulator.o: MCSimulator.cu MCSimulator.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc MCSimulator.cu -o MCSimulator.o -I.

KernelFunctions.o: KernelFunctions.cu
	nvcc -gencode arch=compute_20,code=sm_20 -dc KernelFunctions.cu -o KernelFunctions.o -I.

RandomGenerator.o: RandomGenerator.cu  RandomGenerator.h RandomGeneratorCombined.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc RandomGenerator.cu -o RandomGenerator.o -I.

RandomGeneratorCombined.o: RandomGeneratorCombined.cu  RandomGenerator.h RandomGeneratorCombined.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc RandomGeneratorCombined.cu -o RandomGeneratorCombined.o -I.

RandomGeneratorCombinedGaussian.o:RandomGeneratorCombinedGaussian.cu  RandomGenerator.h RandomGeneratorCombined.h RandomGeneratorCombinedGaussian.h Gaussian.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc RandomGeneratorCombinedGaussian.cu -o RandomGeneratorCombinedGaussian.o -I.

StochasticProcess.o: StochasticProcess.cu StochasticProcess.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc StochasticProcess.cu -o StochasticProcess.o -I.

MonteCarloPath.o: MonteCarloPath.cu MonteCarloPath.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc MonteCarloPath.cu -o MonteCarloPath.o -I.

Option.o: Option.cu Option.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc Option.cu -o Option.o -I.

MonteCarloPricer.o: MonteCarloPricer.cu MonteCarloPricer.h RandomGenerator.h RandomGeneratorCombinedGaussian.h StochasticProcess.h MonteCarloPath.h Option.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc MonteCarloPricer.cu -o MonteCarloPricer.o -I.

Statistics.o: Statistics.cu Statistics.h
	nvcc -gencode arch=compute_20,code=sm_20 -dc Statistics.cu -o Statistics.o -I.

clean:
	rm *.o
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              