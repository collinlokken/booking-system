// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC721/ERC721.sol)

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct Seat {  // this is a data struct that keeps information about seats
    bytes32 id;
    string title;
    string date;
    uint timestamp;
    uint price;
    uint numb;
    uint row;
    string seatView;
    bool booked;
}

contract TicketBookingSystem is ERC721{
    mapping(string => Show) shows;
    mapping(uint=> bytes32) token_to_seat; 
    mapping(uint=> Show) token_to_show;
    string[] showTitles;
    address admin;
    Poster poster;
    
    //Use counter to increment token, each time a token is bought
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    //makes the constructor of the smart contract the admin. Make a new Poster.
    constructor () ERC721 ("Ticket", "TKT") public {
        admin = msg.sender;
        poster = new Poster();
    }


    /*Function for buying a seat. 
    makes a unique seat ID, which is saved in a mapping to enable a token to seatID dictionary. This is used later in order to validitate
    token based on the block timestamp. Require that the correct amount is paid for the ticket and use _safeMint to associate an address
    with a token. 
    */
    function buySeat (string memory _title, string memory _date, uint _numb, uint _row) public payable returns (uint) {
        Show show = shows[_title];
        bytes32 seatId = show.hash(_title,_date,_numb,_row);
        uint seatPrice = show.getSeatPrice(seatId);
        uint tokenId = _tokenIds.current();
        require(msg.value == seatPrice && show.canBuy(_date,_numb,_row), "YOU DIDN'T PAY EXACT AMOUNT");
        mint(msg.sender, _tokenIds.current());
        show.bookSeat(seatId,tokenId,payable(msg.sender));
        token_to_seat[tokenId] = seatId;
        token_to_show[tokenId] = show;
        _tokenIds.increment();
        return tokenId;
    }

    function mint(address _to, uint _tokenId) public {
        _safeMint(_to,_tokenId);
    }

    
    /*
    Checks if the owner of the ticket is correct. If the owner is valid, a unique poster item is issued
    and the ticket is destroyed
    */
    function validate(uint _tokenId) public returns(uint) {
        require(ownerOf(_tokenId)==msg.sender, "The owner of the ticket is invalid.");
        bytes32 seatId = token_to_seat[_tokenId];
        Show show = token_to_show[_tokenId];
        uint timestamp = show.getTimeStamp(seatId);
        require(
            block.timestamp <= timestamp,
            "The ticket has expired"
        );
        require(
            block.timestamp >= timestamp - 2 hours,
            "The validation period hasn't started."
        );
        _burn(_tokenId);
        return poster.releasePoster(msg.sender);

    }
    
    // Make a new show, with title, and available seats. 
    function addShow(string memory _title, uint _availableSeats) public {
        shows[_title] = new Show(_title, _availableSeats);
        showTitles.push(_title);
    }
    
    // add show date and expected timestamp of the planned show. Timestamp is necessary in order to perform validate function later. 
    function addShowDate(string memory _title, string memory _date, uint timestamp) public {
        Show show = shows[_title];
        show.addDate(_date, timestamp);
    }

    function getAllShowTitles () public view returns(string[] memory) {
        return showTitles;
    }

    function getShowDates (string memory _title) public view returns(string[] memory) {
        Show show = shows[_title];
        return show.getDates();
    }
    
    //returns the balance of the smart contract. Shows how much earned in sales tickets. 
    function getBalance () public view returns (uint) {
        return address(this).balance;
    }

    /*
    Function that verifies the validity of a ticket based on the tokenID, and the address it is supposed to be used by 
    */
    function verify (uint tokenId) public view returns (address){
        return ownerOf(tokenId);
    }
    
    /*
    Refunds the ticket of a customer. Refunds can only be issued by the creator of the show
    */
    function refund(string memory _title, uint _tokenId) public {
        require(msg.sender == admin, "YOU ARE NOT THE OWNER OF THE SHOW");
        Show show = shows[_title];
        address payable holder = show.getHolder(_tokenId);
        _burn(_tokenId);
        holder.transfer(10);
        bytes32 seat_id = token_to_seat[_tokenId];
        show.unbookSeat(seat_id);
        // show.destruct(address(this)); // This line should remove the show contract from the block chain, but we did not have time to implement this feature.
    }

    function getShowTokenIds(string memory _title) public view returns (uint[] memory) {
        Show show = shows[_title];
        return show.getTokenIds();
    }

    /*In a trade between two addresses, one of the addresses need to approve the other one, to handle its token. This is not the same as 
    ownerOf, which makes it only possible for accepted second party, to call the buyTicket and trade ticket. It is not possible to 
    validate the token and use it. 
    */
    function approveTrade(address _to, uint tokenId) public payable {
        require(ownerOf(tokenId) == msg.sender);
        approve(_to, tokenId);
    }

    /*Use safeTransferFrom to transfer a tokenID, from the adress that gave you approval to handle its token. And then require that you 
    transfer money from your account to his. 
    */
    function buyTicket (address payable _from, uint _tokenId) public payable{
       uint price = 10;
       require(msg.value == price, "YOU DID NOT PAY EXACT AMOUNT");
       safeTransferFrom(_from, msg.sender, _tokenId);
       _from.transfer(price);
    }

    /*
    Function used to trade tickets between to consenting people. It is required that one of the parties is allowed to perform safeTransferFrom
    the other parties token. Sends my token to you, and then sends your token me. Cannot be performed if i am not allowed to approve trades 
    with your token. 
    */
    function tradeTicket(uint _my_tokenId, uint _your_tokenId) public {
        address myaddress = ownerOf(_my_tokenId);
        address youraddress = ownerOf(_your_tokenId);
        require(_isApprovedOrOwner(myaddress, _your_tokenId));
        safeTransferFrom(myaddress, youraddress, _my_tokenId);
        safeTransferFrom(youraddress, myaddress, _your_tokenId);
    }

}

contract Show {
    /*
    Data structure for storing information about the show
    */
    string public title;
    mapping(bytes32=>Seat) public seats;  // seat id -> Seat
    string[] dateIndex;
    uint private availableSeats;
    address public admin;
    mapping(uint=>address payable) holders;
    uint[] tokenIds;
    //test

    constructor (string memory _title, uint _availableSeats) public {
        title = _title;
        availableSeats = _availableSeats;
        admin = msg.sender;
    }

    /*
    This function iterates through the number of available seats,
    and creates a unique identifier for the seats based on show title,
    date, seat number and row number. 
    
    The set date is added to dateIndex, which is a list of all dates to a show
    */
    function addDate (string memory _date, uint timestamp) public {
        for (uint i = 0; i < availableSeats; i ++){
            uint _price = 10;
            uint _numb = i;
            uint _row = 1;
            bytes32 id = hash(title,_date,_numb,_row);
            

            seats[id] = Seat(id, title, _date, timestamp, _price, _numb, _row, "url:seat-link", false);
        }
        dateIndex.push(_date);
    }

    function setTimeStamp(uint _timestamp, bytes32 _seatId) public view{
        Seat memory seat = seats[_seatId];
        seat.timestamp = _timestamp;
    }    
    
    //Returns the unix encoded timestamp of when a show starts. Each seat in each unique show has the same 
    //time stamp
    function getTimeStamp(bytes32 _seatId) public view returns(uint){
        Seat memory seat = seats[_seatId];
        return seat.timestamp;
    }


    //Checks if a seat is available to be bought. Returns true the seat is available
    function canBuy (string memory _date, uint _numb, uint _row) public view returns(bool) {
        bytes32 seatId = hash(title,_date,_numb,_row);
        Seat memory seat = seats[seatId];
        if (seat.booked == false) {
            return true;
        }
        return false;
    }

    function getTitle ()public view returns(string memory) {
        return title;
    }

    //return all dates of the show
    function getDates () public view returns(string[] memory) {
        return dateIndex;
    }

    
    //Hashes these attributes into a unique identifier. 
    function hash( 
        string memory _title,
        string memory _date,
        uint _numb,
        uint _row
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_title, _date, _numb, _row));
    }

    function getSeatPrice(bytes32 _seatId) public view returns (uint) {
        return seats[_seatId].price;
    }

    function bookSeat(bytes32 _seatId, uint _tokenId, address payable _buyer) public {
        Seat memory seat = seats[_seatId];
        seat.booked = true;
        holders[_tokenId] = _buyer;
        tokenIds.push(_tokenId);
    }

    function getTokenIds () public view returns (uint[] memory) {
        return tokenIds;
    }

    function getHolder(uint _tokenId) public view returns (address payable) {
        return holders[_tokenId];
    }
    
    function unbookSeat (bytes32 _seatId) public {
        seats[_seatId].booked = false;
    }
    
    function destruct (address payable addr) public {
        selfdestruct(addr);
    }

}


contract Poster is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    constructor () ERC721 ("Poster", "PST") {

    }
    
    /*
    Mints and sends a unique poster to an address. 
    */
    function releasePoster (address _to) public returns(uint)
    {
        tokenIds.increment();
        uint newPosterID = tokenIds.current();
        _safeMint(_to, newPosterID);
        return newPosterID;
    }
    
    
}