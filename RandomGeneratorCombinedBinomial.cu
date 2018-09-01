#include "RandomGeneratorCombinedBinomial.h"

__host__ __device__ double RandomGeneratorCombinedBinomial::GetRandomVariable(){
  return this->GetBinomialRandomNumber(this->GetUniformRandomNumber());
};
