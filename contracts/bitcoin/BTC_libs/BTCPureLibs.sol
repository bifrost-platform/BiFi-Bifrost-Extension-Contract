// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../../libs/proxy/ProxyStorage.sol";
import "../state/BTCDataStructure.sol";

import "../utils/L_Bytes.sol";

/**
* @title BiFi-Bifrost-Extension BTCPureLibs Contract
* @notice Library Contract for Bitcoin transaction.
* @author seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo
*/

contract BTCPureLibs is ProxyStorage, BTCDataStructure {
    using L_Bytes for bytes;
    using L_Bytes for bytes32;

    constructor() {}

    /**
    * @dev calculate a merkle root from multiple merkle proofs
    * @param leaves target transaction hashes
    * @param merkleProof a merkle path for each merkle proof
    * @param proofSwitches the byte-indicators implied how to hash on each branch
	* @return a merkle root
	*/
    function computeMultiMerkleRoot(
        bytes32[] calldata leaves,
        bytes32[] calldata merkleProof,
        bytes calldata proofSwitches
    ) external pure returns (bytes32) {
        bytes32 left; bytes32 right;
        uint256 leavespos; uint256 hashpos; uint256 proofpos;

        bytes32[] memory hashes = new bytes32[](proofSwitches.length);

        for(uint256 i; i < proofSwitches.length; i++) {
            if(proofSwitches[i] == 0x01) left = merkleProof[proofpos++];
            else left = (leavespos < leaves.length ? leaves[leavespos++] : hashes[hashpos++]);

            if(proofSwitches[i] == 0x02) right = merkleProof[proofpos++];
            else if(proofSwitches[i] == 0x00) right = left;
            else right = (leavespos < leaves.length ? leaves[leavespos++] : hashes[hashpos++]);

            hashes[ i ] = left.hash256_concat(right);
        }
        // to ensure that the merkle root is calculated from all the given txs and merkle proofs.
        require(leavespos == leaves.length && hashpos == hashes.length-1, "computeMultiMerkleRoot");
        return hashes[ hashes.length-1 ];
    }

    /**
	* @dev Returns specific units (transaction out) from the raw transaction
	* @param rawTX the target transaction in bytes.
	* @param units_indices the indices of the target units in rawTX
	* @return units an array of target units
	*/
    function parse_unit_from_rawTX(
        bytes calldata rawTX,
        uint256[] calldata units_indices
    ) external pure returns (S_Unit[] memory units) {
        // avoid known vulnerability of multi merkle proof
        require(rawTX.length != 64, "btc tx length 64");
        // jump unused field in transaction: version, inputs
        uint256 pos = _calc_output_start_pos(rawTX);

        units = new S_Unit[](units_indices.length);

        uint256 numOutputs;
        uint256 output_script_len;
        // parsing "num of outputs"
        (pos, numOutputs) = _parse_variants_int(rawTX, pos);

        uint256 j=0;
        uint256 amount_pos;

        for(uint256 i; i<numOutputs; i++) {
            // parse units which has "amount" and "BTCaddr" only if the transaction which is pointed by out_indices
            amount_pos = pos;
            pos += 8;
            (pos, output_script_len) = _parse_variants_int(rawTX, pos);

            // check whether this transaction output is pointed by output_indices
            if(
                j < units_indices.length &&
                i == units_indices[j]
            ) {
                // parse "amount" in Satoshi
                units[j].amount = rawTX.parseUint64_bigend(amount_pos);

                // determine output recipient
                // pay-to-pubkey-hash
                if(output_script_len == 0x19) {
                    require(
                        rawTX[pos   ] == 0x76 &&    // OP_DUP
                        rawTX[pos+1 ] == 0xa9 &&    // OP_HASH160
                        rawTX[pos+2 ] == 0x14 &&    // addr len(varint: 20)
                        rawTX[pos+23] == 0x88 &&    // OP_EQUALVERIFY
                        rawTX[pos+24] == 0xac,      // OP_CHECKSIG
                        "invalid P2PKH"
                    );
                    units[j++].BTCaddr = rawTX.parseAddress(pos+3);
                }
                // pay-to-pubkey-hash
                else if(output_script_len == 0x16) {
                    require(
                        rawTX[pos   ] == 0x00 &&    // version(SegWit)
                        rawTX[pos+1 ] == 0x14,      // addr len(varint: 20)
                        "invalid P2WPKH"
                    );
                    units[j++].BTCaddr = rawTX.parseAddress(pos+2);
                }
                // pay-to-script-hash
                else if(output_script_len == 0x17) {
                    require(
                        rawTX[pos   ] == 0xa9 &&    // OP_HASH160
                        rawTX[pos+1 ] == 0x14 &&    // addr len(varint: 20)
                        rawTX[pos+22] == 0x87,      // OP_EQUAL
                        "invalid P2SH"
                    );
                    units[j++].BTCaddr = rawTX.parseAddress(pos+2);
                }
                // revert not supported output script
                else revert("invalid output script");
            }
            pos += output_script_len;
        }
    }

    /**
	* @dev find start_index of "output script" in raw transaction.
	* @param rawTX transaction in bytes
	* @return start_index of "output script"
	*/
    function _calc_output_start_pos(bytes memory rawTX) internal pure returns (uint256) {
        // jump "version" (4 bytes)
        uint256 pos = 4;
        uint256 inputCount;

        //parsing number of "input"
        (pos, inputCount) = _parse_variants_int(rawTX, pos);
        uint256 input_script_len;
        for(uint256 i; i<inputCount; i++) {
            // jump "prev_tx_id" (32 bytes) and "tx_index" (4bytes)
            (pos, input_script_len) = _parse_variants_int(rawTX, pos+36);
            // jump "input_script" (variant size) and "sequence" (4 bytes)
            pos += input_script_len + 4;
        }
        return pos;
    }

    /**
	* @dev read the variant integer
	* @param rawTX target bytes
	* @param pos index to start to read
	* @return bytes index which next field starts
    * @return value of "variants_integer"
	*/
    function _parse_variants_int(bytes memory rawTX, uint256 pos) internal pure returns (uint256, uint256) {
        uint256 varintlength;
        uint256 value;
        bytes1 prefix = rawTX[pos++];

        if( prefix <= 0xFC ) {
            value = uint8(prefix);
        } else if( prefix == 0xFd) {
            varintlength = 2;
            value = rawTX.parseUint16_bigend(pos);
        } else if( prefix == 0xFE) {
            varintlength = 4;
            value = rawTX.parseUint32_bigend(pos);
        } else if( prefix == 0xFF) {
            varintlength = 8;
            value = rawTX.parseUint64_bigend(pos);
        }
        return (pos + varintlength, value);
    }
}