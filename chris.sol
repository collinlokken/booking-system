// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC721/ERC721.sol)

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TicketBookingSystem {
    mapping(string => Show) public shows;
    string[] showTitles;
    
    function buy (string memory _title, string memory _date, uint _numb, uint _row) public view returns (bool) {
        Show show = shows[_title];
        if (show.canBuy(_date,_numb,_row)) {
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
    
}

contract Show {
    string public title;
    mapping(string=>Seat[]) public dates;
    string[] dateIndex;
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
        dateIndex.push(_date);
    }
    
    function canBuy (string memory _date, uint _numb, uint _row) public view returns(bool) {
        Seat[] memory seats = dates[_date];
        for (uint i = 0; i < availableSeats; i++) {
            if (seats[i].numb == _numb && seats[i].row == _row && seats[i].booked == false) {
                return true;
            }
        }
        return false;
    }
    
    function getTitle ()public view returns(string memory) {
        return title;
    }
    
    function getDates () public view returns(string[] memory) {
        return dateIndex;
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

