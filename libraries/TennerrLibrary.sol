//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library TennerrLibrary {
    using SafeMath for uint;


function append(string memory a, string memory b,string memory c,string memory d) internal pure returns (string memory) {

   return string(abi.encodePacked(a, b, c,d));

}

function append(string memory a, string memory b) internal pure returns (string memory) {

   return string(abi.encodePacked(a, b));

}

}
