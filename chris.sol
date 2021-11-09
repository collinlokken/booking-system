// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC721/ERC721.sol)

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TicketBookingSystem {
    Show[] private shows;
    
    function getShowByTitle (string memory _title, string memory _date) public returns (Show) {
        uint showIndex = getShowIndex(_title,_date);
        return shows[showIndex];
    }
    
    function getShowIndex(string memory _title, string memory _date) public returns(uint) {
        for (uint i = 0; i < shows.length; i++) {
            if (keccak256(bytes(shows[i].title)) == keccak256(bytes(_title)) && shows[i].dates[_date]) {
                return i;
            }
        }
        return -1;
    }
    
    function buy (string memory _title, string memory _date, uint _numb, uint _row) public {
        if (getShowByTitle(_title).canBuy(_date,_numb,_row)) {
            
        }
    }
}

contract Show {
    string public title;
    mapping(string=>Seat[]) public dates;
    uint private availableSeats;
    address public admin;
    
    struct Seat {
        string title;
        string date;
        uint price;
        uint numb;
        uint row;
        string seatView;
        bool booked;
    }

    
    constructor (string memory _title, uint _availableSeats) public {
        title = _title;
        availableSeats = _availableSeats;
        admin = msg.sender;

    }
    
    function addDate (string memory _date) public {
        
        for (uint i = 0; i < availableSeats; i ++){
            dates[_date].push(Seat(title, _date, 10, i, 1, "url:seat-link", false));
        }
    }
    
    function canBuy (string memory _date, uint _numb, uint _row) external returns(bool){
        Seat[] memory seats = dates[_date];
        for (uint i = 0; i < availableSeats; i++) {
            if (seats[i].numb == _numb && seats[i].row == _row && seats[i].booked == false) {
                return true;
                
            }
        }
        return false;
    }
    
}


contract Poster is ERC721 {
    constructor () ERC721 ("Poster", "PST") {
        
    }
}

contract Ticket is ERC721 {
    address owner;
    Show show;
    constructor (address _owner, Show _show) ERC721 ("Ticket", "TKT") {
        owner = _owner;
        show = _show;
    }
}
