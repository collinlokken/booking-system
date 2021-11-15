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
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor () public {
        ticket = new Ticket();
    }
    
    function buySeat (string memory _title, string memory _date, uint _numb, uint _row) public payable returns (bool) {
        Show show = shows[_title];
        if (show.canBuy(_date,_numb,_row)) {
            bytes32 seatId = show.hash(_title,_date,_numb,_row);
            uint seatPrice = show.getSeatPrice(_date,seatId);
            require(msg.value == seatPrice, "YOU DIDN'T PAY EXACT AMOUNT");
            ticket.mint(msg.sender, _tokenIds.current(), seatId, show);
            _tokenIds.increment();
            show.bookSeat(_date,seatId);
            return true;
        }
        return false;
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
    
}

contract Show {
    string public title;
    mapping(string=>mapping(bytes32=>Seat)) public dates;  // {"2.des" -> {xyz:1, abc:2}},"3.des" -> ...}
    string[] dateIndex;
    uint private availableSeats;
    address public admin;
    
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
            
            dates[_date][id] = Seat(id, title, _date, _price, _numb, _row, "url:seat-link", false);
        }
        dateIndex.push(_date);
    }
    
    function canBuy (string memory _date, uint _numb, uint _row) public view returns(bool) {
        bytes32 seatId = hash(title,_date,_numb,_row);
        Seat memory seat = dates[_date][seatId];
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
    
    function getSeatPrice(string memory _date, bytes32 _seatId) public view returns (uint) {
        return dates[_date][_seatId].price;
    }
    
    function bookSeat(string memory _date, bytes32 _seatId) public {
        Seat memory seat = dates[_date][_seatId];
        seat.booked = true;
    }
}


contract Poster is ERC721 {
    constructor () ERC721 ("Poster", "PST") {
        
    }
}

contract Ticket is ERC721 {
    mapping(bytes32=>Show) tickets; // seat id --> show
    constructor () ERC721 ("Ticket", "TKT") {}
    
    function mint(address _to, uint _ticketId, bytes32 _seatId, Show _show) public {
        _safeMint(_to,_ticketId);
        tickets[_seatId] = _show;
    }
}

