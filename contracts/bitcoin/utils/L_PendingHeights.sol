// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension L_PendingHeights Library
* @notice Library for pendingHeights structure
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

/**
* @dev meta data structure for the pendingHeights
*/
struct S_PendingHeightsPointer {
    uint64 min;
    uint64 count;
    uint64 size;
}

/**
* @dev data structure of pending heights
*/
struct S_PendingHeights {
    S_PendingHeightsPointer ptr;
    uint64[] data;
}

library L_PendingHeights {

    /**
	* @dev initialize pendingHeights structure and meta data structure
    * @param _pendingHeights the storage pointer
    * @param size buffer max size of pendingHeights
    * @return true
	*/
    function init(S_PendingHeights storage _pendingHeights, uint64 size) internal returns (bool) {
        delete _pendingHeights.data;
        _pendingHeights.data = new uint64[](size);

        S_PendingHeightsPointer memory ptr;
        ptr.size = size;
        _pendingHeights.ptr = ptr;

        return true;
    }

    /**
	* @dev push new item (checking for conflicts internally)
    * @param _pendingHeights the storage pointer
    * @param data item to be pushed
    * @return ptr updated pointer of pendingHeights
	*/
    function push(S_PendingHeights storage _pendingHeights, uint64 data) internal returns (S_PendingHeightsPointer memory ptr) {
        bool success;
        ptr = _pendingHeights.ptr;

        // check collision
        for(uint256 i; i < ptr.size; i++) {
            if(_pendingHeights.data[i] == data) return ptr;
        }

        if(ptr.count == 0) {
            _pendingHeights.data[0] = data;
            ptr.min = data;
            ptr.count++;
            success = true;
        } else if(ptr.count < ptr.size) {
            for(uint256 i; i < ptr.size; i++) {
                if(_pendingHeights.data[i] == 0) {
                    if(ptr.min > data) ptr.min = data;

                    _pendingHeights.data[i] = data;
                    ptr.count++;

                    success = true;
                    break;
                }
            }
        }

        require(success, "push fail");

        _pendingHeights.ptr = ptr;
        return ptr;
    }

    /**
	* @dev pop items less then or equal to specific data
    * @param _pendingHeights the storage pointer
    * @param until criteria
    * @return success true if there is at least one item in the condition, or false
    * @return returndata array popped items
	*/
    function pops(S_PendingHeights storage _pendingHeights, uint64 until) internal returns (bool success, uint64[] memory returndata) {
        S_PendingHeightsPointer memory ptr = _pendingHeights.ptr;

        if(ptr.count == 0) {
            //do nothing since pendingHeights is empty
        } else {
            // need for the function caller to check whether the value equals not to zero (empty)
            returndata = new uint64[](ptr.size);
            uint j=0;

            uint64 tmpData;
            for(uint256 i; i < ptr.size; i++) {
                tmpData = _pendingHeights.data[i];
                if(tmpData == 0) continue;

                if(tmpData <= until) {
                    returndata[j++] = tmpData;
                    _pendingHeights.data[i] = 0;
                    success = true;
                    ptr.count--;
                } else {
                    if(ptr.min >= tmpData) ptr.min = tmpData;
                }
            }
            _pendingHeights.ptr = ptr;
        }
    }

    /**
	* @dev return all item without modification of storage
    * @param _pendingHeights the storage pointer
    * @return ptr pendingHeights pointer
    * @return returndata array of items
	*/
    function peeks(S_PendingHeights storage _pendingHeights) internal view returns (S_PendingHeightsPointer memory ptr, uint64[] memory returndata) {
        ptr = _pendingHeights.ptr;

        if(ptr.count == 0) {
            //do nothing since pendingHeights is empty
        } else {
            // need for the function caller to check whether the value equals not to zero (empty)
            returndata = new uint64[](ptr.size);
            uint j=0;

            uint64 tmpData;
            for(uint256 i; i < ptr.size; i++) {
                tmpData = _pendingHeights.data[i];
                if(tmpData == 0) continue;

                returndata[j++] = tmpData;
            }
        }
    }

    /**
	* @dev pop data by value limit
    * @param _pendingHeights the storage pointer
    * @param valueLimit condition value of data pop
    * @return success true for success, fail for not matched condition until
    * @return returndata array of data
	*/
    function rollbackPops(S_PendingHeights storage _pendingHeights, uint64 valueLimit) internal returns (bool success, uint64[] memory returndata) {
        S_PendingHeightsPointer memory ptr = _pendingHeights.ptr;

        if(ptr.count == 0) {
            //noting to do
        } else {
            //do nothing since pendingHeights is empty
            returndata = new uint64[](ptr.size);
            uint j=0;

            uint64 tmpData;
            for(uint256 i; i < ptr.size; i++) {
                tmpData = _pendingHeights.data[i];
                if(tmpData == 0) continue;

                if(tmpData >= valueLimit) {
                    returndata[j++] = tmpData;
                    _pendingHeights.data[i] = 0;
                    success = true;
                    ptr.count--;
                }
            }
            _pendingHeights.ptr = ptr;
        }
    }
}