#include "RootSignature.h"
#include <map>

using namespace std;

void RootSignature::Reset(UINT paramsNum, UINT samplersNum)
{
	if (paramsNum > 0)
		mParamArray.reset(new RootParameter[paramsNum]);
	else
		mParamArray = nullptr;
	mParamsNum = paramsNum;

	if (samplersNum > 0)
		mSamplerArray.reset(new CD3DX12_STATIC_SAMPLER_DESC[samplersNum]);
	else
		mSamplerArray = nullptr;
	mSamplersNum = samplersNum;
}