// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
// https://www.youtube.com/watch?v=ajCsPRl5S3Q&list=PLO5VPQH6OWdVQwpQfw9rZ67O6Pjfo6q-p&index=50
pragma solidity ^0.8.13;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed  txId);
    event Revoke(address indexed amount, uint indexed txId);
    event Execute(uint indexed txId);
    
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;
    
    Transaction[]  public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(
            _required > 0 && _required <= _owners.length, 
            "invalid required number of owners"
        );
        for(uint i; i< _owners.length; i++){
            address owner = _owners[i];
            require(owner!= address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable{
        emit Deposit(msg.sender, msg.value);
    }


    function submit(
        address _to, uint _value, bytes calldata _data
    ) external onlyOwner{
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false
            }));
        emit Submit(transactions.length -1);
    }
    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier notExecuted(uint _txId){
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }
    modifier notApproved(uint _txId){
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }
    modifier txExists(uint _txId){
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    function approve(
        uint _txId
    ) external 
        onlyOwner 
        txExists(_txId) 
        notApproved(_txId) 
        notExecuted(_txId) 
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count){
        for(uint i; i< owners.length; i++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
    }

    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "Need more aprovals");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
        emit Execute(_txId);
    }
    function revoke(uint _txId)
        external
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId)
    {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}