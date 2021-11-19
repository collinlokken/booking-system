// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC721/ERC721.sol)

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct Seat {
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

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor () ERC721 ("Ticket", "TKT") public {
        admin = msg.sender;
        poster = new Poster();
    }

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

    function validate(uint _tokenId) public {
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
        poster.releasePoster(msg.sender);

    }

    function addShow(string memory _title, uint _availableSeats) public {
        shows[_title] = new Show(_title, _availableSeats);
        showTitles.push(_title);
    }

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

    function getBalance () public view returns (uint) {
        return address(this).balance;
    }

    function verify (uint tokenId) public view returns (address){
        return ownerOf(tokenId);
    }

    function refund(string memory _title, uint _tokenId) public {
        require(msg.sender == admin, "YOU ARE NOT THE OWNER OF THE SHOW");
        Show show = shows[_title];
        address payable holder = show.getHolder(_tokenId);
        _burn(_tokenId);
        holder.transfer(10);
        bytes32 seat_id = token_to_seat[_tokenId];
        show.unbookSeat(seat_id);
        // show.destruct(address(this));
    }

    function getShowTokenIds(string memory _title) public view returns (uint[] memory) {
        Show show = shows[_title];
        return show.getTokenIds();
    }

    function AmIApproved(uint _tokenID) public view returns(address){
        //approve(_to, _tokenID);
        return (ownerOf(_tokenID));
    }


    function approveTrade(address _to, uint tokenId) public payable {
        require(ownerOf(tokenId) == msg.sender);
        approve(_to, tokenId);
    }


    function tradeTicket (address payable _from, uint _tokenId) public payable{
       uint price = 10;
       require(msg.value == price, "YOU DID NOT PAY EXACT AMOUNT");
       safeTransferFrom(_from, msg.sender, _tokenId);
       _from.transfer(price);
    }

    function tradeTicket(uint _my_tokenId, uint _your_tokenId) public {
        address myaddress = ownerOf(_my_tokenId);
        address youraddress = ownerOf(_your_tokenId);
        require(_isApprovedOrOwner(myaddress, _your_tokenId));
        safeTransferFrom(myaddress, youraddress, _my_tokenId);
        safeTransferFrom(youraddress, myaddress, _your_tokenId);
    }

}

contract Show {
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
    
    function getTimeStamp(bytes32 _seatId) public view returns(uint){
        Seat memory seat = seats[_seatId];
        return seat.timestamp;
    }

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

    function getDates () public view returns(string[] memory) {
        return dateIndex;
    }

    function hash( // * slaps roof * "ripped this puppy of the good'ol web" -Me, 2021
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

    function releasePoster (address _to) public returns(uint)
    {
        tokenIds.increment();
        uint newPosterID = tokenIds.current();
        _safeMint(_to, newPosterID);
        return newPosterID;
    }
    
    
}