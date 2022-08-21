// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.13;

contract ArrayShift {
    uint[] public arr;
    
    function examples() external {
        arr = [1, 2, 3];
        delete arr[1]; // [1, 0, 3]
    }

    function remove(uint _index) public {
        require( _index < arr.length, "index out of bound");   
        for( uint i = _index; i < arr.length -1; i++){
            arr[i]= arr [i + 1];
        }
        arr.pop(); // remove last element
    }
    
    function test() external {
        arr = [1, 2, 3, 4, 5];
        remove(2); // [1, 2, 4, 5]
        assert(arr.length == 4);
        assert(arr[0] == 1);
        assert(arr[1] == 2);
        assert(arr[2] == 4);
        assert(arr[3] == 5);

        arr = [1];
        remove(0);
        assert(arr.length == 0);
    } 
}
