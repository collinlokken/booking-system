// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC721/ERC721.sol)

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct Seat {
    bytes32 id;
    string title;
    string date;
    uint price;
    uint numb;
    uint row;
    string seatView;
    bool booked;
}

contract TicketBookingSystem {
    mapping(string => Show) shows;
    string[] showTitles;
    Ticket ticket;
    address admin;
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor () public {
        ticket = new Ticket();
        admin = msg.sender;
    }
    
    function cancelShow(string memory _title) public {
        require(msg.sender == admin, "YOU ARE NOT THE OWNER OF THE SHOW");
        Show show = shows[_title];
        for (uint i = 0; i < show.getTicketsSold(); i ++){
            uint tokenId = show.getTokenIds()[i];
            address payable holder = show.getHolder(tokenId);
            ticket.burn(tokenId);
            holder.transfer(10);
        }
        
    }
    
    function buySeat (string memory _title, string memory _date, uint _numb, uint _row) public payable returns (uint) {
        Show show = shows[_title];
        bytes32 seatId = show.hash(_title,_date,_numb,_row);
        uint seatPrice = show.getSeatPrice(seatId);
        uint tokenId = _tokenIds.current();
        require(msg.value == seatPrice && show.canBuy(_date,_numb,_row), "YOU DIDN'T PAY EXACT AMOUNT");
        ticket.mint(msg.sender, _tokenIds.current(), seatId, show);
        show.bookSeat(seatId,tokenId,payable(msg.sender));
        
        _tokenIds.increment();
        return tokenId;
    }
    
    function addShow(string memory _title, uint _availableSeats) public {
        shows[_title] = new Show(_title, _availableSeats);
        showTitles.push(_title);
    }
    
    function addShowDate(string memory _title, string memory _date) public {
        Show show = shows[_title];
        show.addDate(_date);
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
    
    function verify (uint tokenId, address tryhard) public view returns (bool){
        require (ticket.ownerOf(tokenId) == tryhard, "INPUT ADDRESS WAS NOT TOKEN OWNER");
        return true;
    }
    
}

contract Show {
    string public title;
    mapping(bytes32=>Seat) public seats;  // {xyz:1, abc:2}
    string[] dateIndex;
    uint private availableSeats;
    address public admin;
    mapping(uint=>address payable) holders;
    uint ticketsSold;
    uint[] tokenIds;
    
    
    constructor (string memory _title, uint _availableSeats) public {
        title = _title;
        availableSeats = _availableSeats;
        admin = msg.sender;
    }
    
    function addDate (string memory _date) public {
        for (uint i = 0; i < availableSeats; i ++){
            uint _price = 10;
            uint _numb = i;
            uint _row = 1;
            bytes32 id = hash(title,_date,_numb,_row);
            
            seats[id] = Seat(id, title, _date, _price, _numb, _row, "url:seat-link", false);
        }
        dateIndex.push(_date);
    }
    
    function addTokenIDtoSeat(uint _tokenID) public view{
        
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
        ticketsSold ++;
        tokenIds.push(_tokenId);
    }
    
    function getTicketsSold () public view returns (uint) {
        return ticketsSold;
    }
    
    function getTokenIds () public view returns (uint[] memory) {
        return tokenIds;
    }
    
    function getHolder(uint _tokenId) public view returns (address payable) {
        return holders[_tokenId];
    }
    
}


contract Poster is ERC721 {
    constructor () ERC721 ("Poster", "PST") {
        
    }
}

contract Ticket is ERC721 {
    mapping(bytes32=>Show) tickets; // seat id --> show
    
    constructor () ERC721 ("Ticket", "TKT") {}
    
    function mint(address _to, uint _tokenId, bytes32 _seatId, Show _show) public {
        _safeMint(_to,_tokenId);
        tickets[_seatId] = _show;
    }
    
    function burn(uint _tokenId) public {
        _burn(_tokenId);
    }
}