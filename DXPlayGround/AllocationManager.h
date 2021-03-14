#pragma once

#include "d3dUtil.h"

class AllocationManager
{
	using OffsetType = size_t;

private:
	struct FreeBlockInfo;
	using FreeBlocksOffsetMap =
		std::map<OffsetType, FreeBlockInfo, std::less<OffsetType>>;

	using FreeBlocksSizeMap =
		std::map<OffsetType, FreeBlocksOffsetMap::iterator, std::less<OffsetType>>;

	struct FreeBlockInfo
	{
		OffsetType Size;
		FreeBlocksSizeMap::iterator OrderBySizeIt;
		FreeBlockInfo(OffsetType _size) :
			Size(_size) {}
	};

public:
	struct Allocation
	{
		static Allocation InvalidAllocation()
		{
			return Allocation();
		}
	};

	Allocation Allocate(OffsetType size, OffsetType alignment);

	void Free(Allocation&& allocation);

	void Free(OffsetType offset, OffsetType size);

private:
	void AddNewBlock(OffsetType offset, OffsetType size);
	FreeBlocksOffsetMap mFreeBlocksByOffset;
	FreeBlocksSizeMap mFreeBlocksBySize;

	OffsetType mMaxSize = 0;
	OffsetType mFreeSize = 0;
	OffsetType mCurrAlignment = 0;
};