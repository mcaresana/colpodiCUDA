/*####################################################################################################
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
    __host__ __device__ virtual void Step(UnderlyingPrice*, double TimeStep, double RandomNumber)=0;
    __host__ __device__ virtual double GetRandomNumber()=0;
protected:
    RandomGenerator* _Generator;
};

class ExactLogNormalProcess: public StocasticProcess{
public:
    __host__ __device__ ExactLogNormalProcess(RandomGenerator* Generator);
    __host__ __device__ void Step(UnderlyingPrice * Step, double TimeStep, double RandomNumber);
    __host__ __device__ double GetRandomNumber();
};

class EulerLogNormalProcess: public StocasticProcess{
public:
    __host__ __device__ EulerLogNormalProcess(RandomGenerator* Generator);
    __host__ __device__ void Step(UnderlyingPrice * Step, double TimeStep, double RandomNumber);
    __host__ __device__ double GetRandomNumber();
};

#endif
