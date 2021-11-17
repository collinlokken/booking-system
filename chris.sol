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

contract TicketBookingSystem is ERC721{
    mapping(string => Show) shows;
    string[] showTitles;
    address admin;
    mapping(bytes32=>Show) tickets; // seat id --> show

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor () ERC721 ("Ticket", "TKT") public {
        //ticket = new Ticket();
        admin = msg.sender;
    }

    modifier showOwner(){
        require(msg.sender == admin);
        _;
    }


    function buySeat (string memory _title, string memory _date, uint _numb, uint _row) public payable returns (uint) {
        Show show = shows[_title];
        bytes32 seatId = show.hash(_title,_date,_numb,_row);
        uint seatPrice = show.getSeatPrice(seatId);
        uint tokenId = _tokenIds.current();
        require(msg.value == seatPrice && show.canBuy(_date,_numb,_row), "YOU DIDN'T PAY EXACT AMOUNT");
        mint(msg.sender, _tokenIds.current(), seatId, show);
        show.bookSeat(seatId,tokenId,payable(msg.sender));

        _tokenIds.increment();
        return tokenId;
    }


    function mint(address _to, uint _tokenId, bytes32 _seatId, Show _show) public {
        _safeMint(_to,_tokenId);
        tickets[_seatId] = _show;
    }

    function burn(uint _tokenId) public {
        _burn(_tokenId);
    }

    function validate(uint _tokenId) public {
        require(

            tickets.ownerOf(tokenId) == msg.sender,
            "The owner of the ticket is invalid."
        );
        require();

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
        require (ownerOf(tokenId) == tryhard, "INPUT ADDRESS WAS NOT TOKEN OWNER");
        return true;
    }

    function refund(string memory _title, uint _tokenId) public {
        require(msg.sender == admin, "YOU ARE NOT THE OWNER OF THE SHOW");
        Show show = shows[_title];
        address payable holder = show.getHolder(_tokenId);
        burn(_tokenId);
        holder.transfer(10);
    }

    function getShowTokenIds(string memory _title) public view returns (uint[] memory) {
        Show show = shows[_title];
        return show.getTokenIds();
    }

    // f.eks fra brage til chris.
    // TODO: brage må approve chris
    // chris kjører trade og overfører til seg selv MEN må også sende med value = price

    //må gi tillatelse til chris slik at han kan kjøre safeTransferFrom
    //Bruker approve funksjonen
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
    mapping(bytes32=>Seat) public seats;  // {xyz:1, abc:2}
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
        tokenIds.push(_tokenId);
    }

    function getTokenIds () public view returns (uint[] memory) {
        return tokenIds;
    }

    function getHolder(uint _tokenId) public view returns (address payable) {
        return holders[_tokenId];
    }

}


contract Poster is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    constructor () ERC721 ("Poster", "PST") {

    }

    modifier posterMinter(){
        require(msg.sender == admin);
        _;
    }

    function releasePoster (address _to, uint _tokenIds) public posterMinter returns(uint)
    {
        tokenIds.increment();
        uint newPosterID = tokenIds.current();
        _safeMint(_to, newPosterID);
        return newPosterID;
    }
}
