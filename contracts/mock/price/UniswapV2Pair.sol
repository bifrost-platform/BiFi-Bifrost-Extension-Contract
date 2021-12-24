// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "../../interfaces/IUniswapV2Pair.sol";

/**
* @title BiFi-Bifrost-Extension UniswapV2Pair Contract
* @notice Contract for uniswap pair mockup of BFC-ETH, return pair reserve amount, will use TWAP price of BFC/ETH(18)
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

// Ethereum mainnet, uniswap bfc pair: 0x01688e1a356c38A8ED7C565BF6c6bfd59543a560
contract UniswapV2Pair is IUniswapV2Pair {
    function getReserves() override external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        reserve0 = 44652191091221624110408452;
        reserve1 = 788294879071394736464;
    }
}