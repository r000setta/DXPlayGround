#include "AllocationManager.h"

AllocationManager::Allocation AllocationManager::Allocate(OffsetType size, OffsetType alignment)
{
	if (mFreeSize < size)
		return Allocation::InvalidAllocation();
	auto alignReserve = (alignment > mCurrAlignment) ? alignment - mCurrAlignment : 0;
	auto smallestBlockItIt = mFreeBlocksBySize.lower_bound(size + alignReserve);
	if (smallestBlockItIt == mFreeBlocksBySize.end())
		return Allocation::InvalidAllocation();
	auto smallestBlockIt = smallestBlockItIt->second;
	auto offset = smallestBlockIt->first;
	auto newOffset = offset + size;
	auto newSize = smallestBlockIt->second.Size - size;
	mFreeBlocksBySize.erase(smallestBlockItIt);
	mFreeBlocksByOffset.erase(smallestBlockIt);
	if (newSize > 0)
		AddNewBlock(newOffset, newSize);
	mFreeSize -= size;
	return Allocation();
}

void AllocationManager::Free(Allocation&& allocation)
{
}

void AllocationManager::Free(OffsetType offset, OffsetType size)
{
}

void AllocationManager::AddNewBlock(OffsetType offset, OffsetType size)
{
}
