// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";

contract NFTRaffleContract {
    
    address public owner;
    mapping(address => uint256) public entryCount;
    address[] public players;
    address[] private playerSelector;
    bool public raffleStatus;
    uint256 public entryCost;
    address public nftAddress;
    uint256 public nftId;
    uint256 public totalEntries;

    event NewEntry(address player);
    event RaffleStarted();
    event RaffleEnded();
    event WinnerSelected(address winner);
    event EntryCostChanged(uint256 newCost);
    event NFTPrizeSet(address nftAddress, uint256 nftId);
    event BalanceWithdrawn(uint256 amount);

    constructor(uint256 _entryCost) {
        owner = msg.sender;
        entryCost = _entryCost;
        raffleStatus = false;
        totalEntries = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function!");
        _;
    }

    function startRaffle(address _nftContract, uint256 _tokenID) public onlyOwner {
        require(!raffleStatus, "Raffle is already started");
        require(nftAddress == address(0), "NFT prize already set. Please select winner from previous raffle");
        require(
            ERC721Base(_nftContract).ownerOf(_tokenID) == address(this),
            "Owner does not own the NFT"
        );

        nftAddress = _nftContract;
        nftId = _tokenID;
        raffleStatus = true;
        emit RaffleStarted();
        emit NFTPrizeSet(_nftContract, _tokenID);
    }

    function buyEntry(uint256 _numberOfEntries) public payable {
        require(raffleStatus, "Raffle is not started");
        require(msg.value == entryCost * _numberOfEntries, "Incorrect amount sent");

        entryCount[msg.sender] += _numberOfEntries;
        totalEntries += _numberOfEntries;

        if(!isPlayer(msg.sender)) {
            players.push(msg.sender);
        }

        for (uint256 i = 0; i < _numberOfEntries; i++) {
            playerSelector.push(msg.sender);
        }

        emit NewEntry(msg.sender);
    }

    function isPlayer(address _player) public view returns(bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if(players[i] == _player){
                return true;
            }
        }
        return false;
    }

    function endRaffle() public onlyOwner {
        require(raffleStatus, "Raffle is not started");
        raffleStatus = false;
        emit RaffleEnded();
    }

    function selectWinner() public onlyOwner {
        require(!raffleStatus, "Raffle is still running");
        require(playerSelector.length > 0, "No players in raffle");
        require(nftAddress != address(0), "NFT prize not set");

        uint256 winnerIndex = random() % playerSelector.length;
        address winner = playerSelector[winnerIndex];
        emit WinnerSelected(winner);

        ERC721Base(nftAddress).transferFrom(owner, winner, nftId);

        resetEntryCounts();
        delete playerSelector;
        delete players;
        nftAddress = address(0);
        nftId = 0;
        totalEntries = 0;
    }

    function random() private view returns (uint256) {
        return 
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function resetEntryCounts() private {
        for (uint256 i = 0; i < players.length; i++) {
            entryCount[players[i]] = 0;
        }
    }

    function changeEntryCost(uint256 _newCost) public onlyOwner {
        require(!raffleStatus, "Raffle is still running");

        entryCost = _newCost;
        emit EntryCostChanged(_newCost);
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        uint256 balanceAmount = address(this).balance;

        payable(owner).transfer(balanceAmount);
        emit BalanceWithdrawn(balanceAmount);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;        
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function resetContract() public onlyOwner {
        delete playerSelector;
        delete players;
        raffleStatus = false;
        nftAddress = address(0);
        nftId = 0;
        entryCost = 0;
        totalEntries = 0;
        resetEntryCounts();
    }

}
