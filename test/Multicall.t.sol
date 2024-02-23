// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/ds-test/src/test.sol";
import "../contract/Multicall.sol";

contract Store {
    uint256 internal val;

    function set(uint256 _val) public {
        val = _val;
    }

    function get() public view returns (uint256) {
        return val;
    }

    function getAnd10() public view returns (uint256, uint256) {
        return (val, 10);
    }

    function getAdd(uint256 _val) public view returns (uint256) {
        return val + _val;
    }
}

contract MulticallTest is DSTest, Multicall {
    Store public storeA;
    Store public storeB;

    function setUp() public {
        storeA = new Store();
        storeB = new Store();
    }

    function test_store_basic_sanity() public {
        assertEq(storeA.get(), 0);
        storeA.set(100);
        assertEq(storeA.get(), 100);
        storeA.set(0);
        assertEq(storeA.get(), 0);
    }

    function test_single_call_single_return_no_args() public {
        storeA.set(123);

        Call[] memory _calls = new Call[](1);
        _calls[0].target = address(storeA);
        _calls[0].callData = abi.encodeWithSignature("get()");

        (, bytes[] memory _returnData) = aggregate(_calls);

        bytes memory _word = _returnData[0];
        uint256 _returnVal;
        assembly {
            _returnVal := mload(add(0x20, _word))
        }

        assertEq(_returnVal, 123);
    }

    function test_multi_call_single_return_no_args() public {
        storeA.set(123);
        storeB.set(321);

        Call[] memory _calls = new Call[](2);
        _calls[0].target = address(storeA);
        _calls[0].callData = abi.encodeWithSignature("get()");
        _calls[1].target = address(storeB);
        _calls[1].callData = abi.encodeWithSignature("get()");

        (, bytes[] memory _returnData) = aggregate(_calls);

        bytes memory _wordA = _returnData[0];
        bytes memory _wordB = _returnData[1];
        uint256 _returnValA;
        uint256 _returnValB;
        assembly {
            _returnValA := mload(add(0x20, _wordA))
        }
        assembly {
            _returnValB := mload(add(0x20, _wordB))
        }

        assertEq(_returnValA, 123);
        assertEq(_returnValB, 321);
    }

    function test_single_call_single_return_single_arg() public {
        storeA.set(123);

        Call[] memory _calls = new Call[](1);
        _calls[0].target = address(storeA);
        _calls[0].callData = abi.encodeWithSignature("getAdd(uint256)", 1);

        (, bytes[] memory _returnData) = aggregate(_calls);

        bytes memory _word = _returnData[0];
        uint256 _returnVal;
        assembly {
            _returnVal := mload(add(0x20, _word))
        }

        assertEq(_returnVal, 124);
    }

    function test_multi_call_single_return_single_arg() public {
        storeA.set(123);
        storeB.set(321);

        Call[] memory _calls = new Call[](2);
        _calls[0].target = address(storeA);
        _calls[0].callData = abi.encodeWithSignature("getAdd(uint256)", 1);
        _calls[1].target = address(storeB);
        _calls[1].callData = abi.encodeWithSignature("getAdd(uint256)", 1);

        (, bytes[] memory _returnData) = aggregate(_calls);

        bytes memory _wordA = _returnData[0];
        bytes memory _wordB = _returnData[1];
        uint256 _returnValA;
        uint256 _returnValB;
        assembly {
            _returnValA := mload(add(0x20, _wordA))
        }
        assembly {
            _returnValB := mload(add(0x20, _wordB))
        }

        assertEq(_returnValA, 124);
        assertEq(_returnValB, 322);
    }

    function test_single_call_multi_return_no_args() public {
        storeA.set(123);

        Call[] memory _calls = new Call[](1);
        _calls[0].target = address(storeA);
        _calls[0].callData = abi.encodeWithSignature("getAnd10()");

        (, bytes[] memory _returnData) = aggregate(_calls);

        bytes memory _words = _returnData[0];
        uint256 _returnValA1;
        uint256 _returnValA2;
        assembly {
            _returnValA1 := mload(add(0x20, _words))
        }
        assembly {
            _returnValA2 := mload(add(0x40, _words))
        }

        assertEq(_returnValA1, 123);
        assertEq(_returnValA2, 10);
    }

    function test_helpers() public {
        bytes32 blockHash = getBlockHash(510);
        bytes32 lastBlockHash = getLastBlockHash();
        uint256 timestamp = getCurrentBlockTimestamp();
        uint256 gaslimit = getCurrentBlockGasLimit();
        uint256 balance = getEthBalance(address(this));

        assertEq(blockHash, blockhash(510));
        assertEq(lastBlockHash, blockhash(block.number - 1));
        assertEq(timestamp, block.timestamp);
        assertEq(gaslimit, block.gaslimit);
        assertEq(balance, address(this).balance);
    }
}




// contract MulticallTest is DSTest {
//     Multicall public multicall; // Instance of the Multicall contract
//     address public testAddress; // Address to test

//     // Deploy the Multicall contract and set the test address before each test
//     function beforeEach() external {
//         multicall = new Multicall();
//         testAddress = address(0xF5bDd4b5181B6a17d3593743912A5E233Acfa7c5); 
//     }

//     // Test case to check the balance of the test address
//     function testGetEthBalance() public{
//         uint256 balance = multicall.getEthBalance(testAddress);
//         assertEq(balance, testAddress.balance, "Incorrect balance");
//     }

//     // Test case to check the block hash
//     function testGetBlockHash() external {
//         // Call the getBlockHash function of the Multicall contract
//         bytes32 blockHash = multicall.getBlockHash(10583625); 
//        assertEq(blockHash, blockhash(0x952f7b01e5262833871ee65f9ff848ee5f8b1d7140724a048deed14be3e4873f), "Incorrect block hash");
//     }

//     // Test case to check the last block hash
//     function testGetLastBlockHash() external {
//         bytes32 lastBlockHash = multicall.getLastBlockHash();
//         assertEq(lastBlockHash, blockhash(block.number - 1), "Incorrect last block hash");
//     }

//     // Test case to check the current block timestamp
//     function testGetCurrentBlockTimestamp() external {
//         uint256 timestamp = multicall.getCurrentBlockTimestamp();
//         assertEq(timestamp, block.timestamp, "Incorrect timestamp");
//     }

//     // Test case to check the current block gas limit
//     function testGetCurrentBlockGasLimit() external {
//         uint256 gasLimit = multicall.getCurrentBlockGasLimit();
//         assertEq(gasLimit, block.gaslimit, "Incorrect gas limit");
//     }
// }
