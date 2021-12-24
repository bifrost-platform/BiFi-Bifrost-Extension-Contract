// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension L_Bytes Library
* @notice Library for bytes utils
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

library L_Bytes {
    /**
    * @dev the HASH256 function: ripemd(sha256(*))
    * @param data pre-image to be hashed (little endian)
    * @return bytes32 hash value (little endian)
	*/
    function hash256_littleend(bytes memory data) internal pure returns (bytes32) {
        return sha256(abi.encode(sha256(data)));
    }

    /**
    * @dev the HASH256 function: ripemd(sha256(*))
    * @param rawHeader pre-image to be hashed (little endian)
    * @return bytes32 hash value (big endian)
	*/
    function hash256_bigend(bytes memory rawHeader) internal pure returns (bytes32) {
        return toBigend( sha256(abi.encode(sha256(rawHeader))) );
    }

    /**
    * @dev the HASH256 function with concatenation of two pre-images
    * @param leftData first pre-image
    * @param rightData second pre-image
    * @return bytes32 hash value (little-endian)
	*/
    function hash256_concat(bytes32 leftData, bytes32 rightData) internal pure returns (bytes32) {
        return sha256(abi.encode(sha256(abi.encode( leftData, rightData ))));
    }

    /**
    * @dev parsing merkle root from Bitcoin header
    * @notice use carefully, it does not check length of input in order to save gas fee
    * @param _source bytes of Bitcoin header
    * @return result merkle root
	*/
    function parseMerkleRoot(bytes memory _source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(_source, 68))
        }
    }
    /**
    * @dev parsing previous header hash from Bitcoin header_bytes
    * @notice use carefully, it does not check length of input in order to save gas fee
    * @param _source bytes of Bitcoin header
    * @return result previous header hash
	*/
    function parsePreHash(bytes memory _source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(_source, 36))
        }
        return toBigend(result);
    }

    /**
    * @dev parsing timestamp from Bitcoin header
    * @notice use carefully, it does not check length of input in order to save gas fee
    * @param _bytes bytes of bitcoin header
    * @return result timestamp integer (big endian)
	*/
    function parseTimestamp(bytes memory _bytes) internal pure returns (uint32 result) {
        assembly {
            result := mload( add(_bytes, 72) )
        }
        // endian conversion
        result = ((result & 0xFF00FF00) >> 8) | ((result & 0x00FF00FF) << 8);
        result = (result >> 16) | (result << 16);
    }

    /**
    * @dev parse a header (80 bytes) from bytes which are arbitrary number of concatenated headers
    * @notice use carefully, it does not check length of input in order to save gas fee
    * @param _bytes concatenated bytes of arbitrary number of headers
    * @param _start starting index to read
    * @return resultHeader a single bitcoin header
	*/
    function sliceHeader(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory resultHeader) {
        assembly {
            resultHeader := mload(0x40)

            let mc := add(resultHeader, 16)
            let cc := add(add(_bytes, _start), 16)

            mstore(mc, mload(cc))
            mc := add(mc, 0x20)
            cc := add(cc, 0x20)
            mstore(mc, mload(cc))
            mc := add(mc, 0x20)
            cc := add(cc, 0x20)
            mstore(mc, mload(cc))
            mc := add(mc, 0x20)

            mstore(resultHeader, 80)
            mstore(0x40, and(add(mc, 31), not(31)))
        }
    }

    /**
    * @dev parse 20 bytes from input bytes, return it as an address
    * @notice use carefully, it does not check length of input in order to save gas fee
    * @param _bytes target bytes
    * @param offset starting index to read
    * @return result a address
	*/
    function parseAddress(bytes memory _bytes, uint256 offset) internal pure returns (address result) {
        // require(_bytes.length >= 20, "parseAddress.");
        assembly {
            result := mload( add(add(_bytes, offset), 20) )
        }
    }

    /**
    * @dev parse 8 bytes from input bytes, return it as an uint64
    * @notice use carefully, it does not check length of input in order to save gas fee
    * @param _bytes target bytes (little endian)
    * @param offset starting index to read
    * @return result a uint64
	*/
    function parseUint64_bigend(bytes memory _bytes, uint256 offset) internal pure returns (uint64 result) {
        // require(_bytes.length >= 8, "parseUint64.");
        assembly {
            result := mload(add(add(_bytes, offset), 8))
        }

        result = ((result & 0xFF00FF00FF00FF00) >> 8) |
                 ((result & 0x00FF00FF00FF00FF) << 8);

        // endian conversion
        result = ((result & 0xFFFF0000FFFF0000) >> 16) | ((result & 0x0000FFFF0000FFFF) << 16);
        result = (result >> 32) | (result << 32);
    }

    /**
    * @dev parse 4 bytes from input bytes, return it as an uint32
    * @notice use carefully, it does not check length of input in order to save gas fee
    * @param _bytes target bytes (little endian)
    * @param offset starting index to read
    * @return result a uint32
	*/
    function parseUint32_bigend(bytes memory _bytes, uint256 offset) internal pure returns (uint32 result) {
        // require(_bytes.length >= 4, "parseUint32_bigend.");
        assembly {
            result := mload( add(add(_bytes, offset),4) )
        }
        // endian conversion
        result = ((result & 0xFF00FF00) >> 8) | ((result & 0x00FF00FF) << 8);
        result = (result >> 16) | (result << 16);
    }

    /**
    * @dev parse 2 bytes from input bytes, return it as an uint16
    * @notice use carefully, it does not check length of input in order to save gas fee
    * @param _bytes target bytes (little endian)
    * @param offset starting index to read
    * @return result a uint16
	*/
    function parseUint16_bigend(bytes memory _bytes, uint256 offset) internal pure returns (uint16 result) {
        // require(_bytes.length >= 4, "parseUint16_bigend.");
        assembly {
            result := mload( add(add(_bytes, offset),2) )
        }
        // endian conversion
        result = (result >> 8) | (result << 8);
    }

    /**
    * @dev convert little endian bytes32 to big-endian (vice versa)
    * @param input bytes32
    * @return result reversed bytes32
	*/
    function toBigend(bytes32 input) internal pure returns (bytes32) {
        // swap bytes
        input = ((input & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
                ((input & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte pairs
        input = ((input & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
                ((input & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte pairs
        input = ((input & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
                ((input & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte pairs
        input = ((input & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
                ((input & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte pairs
        return (input >> 128) | (input << 128);
    }
}