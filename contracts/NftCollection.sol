// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NftCollection {

    // ------------------------------
    // Metadata
    // ------------------------------
    string public name;
    string public symbol;

    uint256 public maxSupply;
    uint256 public totalSupply;

    // tokenId => owner
    mapping(uint256 => address) private _owners;

    // owner => number of owned tokens
    mapping(address => uint256) private _balances;

    // tokenId => approved address
    mapping(uint256 => address) private _tokenApprovals;

    // owner => (operator => approved)
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    // ------------------------------
    // Access Control
    // ------------------------------
    address private _admin;
    bool public mintPaused = false;

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Not authorized");
        _;
    }


    // ------------------------------
    // Events (ERC-721 Standard)
    // ------------------------------
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // ------------------------------
    // Constructor
    // ------------------------------
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) {
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
        _admin = msg.sender;
    }


    // ------------------------------
    // Admin Functions
    // ------------------------------
    function pauseMinting() external onlyAdmin {
        mintPaused = true;
    }

    function unpauseMinting() external onlyAdmin {
        mintPaused = false;
    }


    // ------------------------------
    // Metadata Base URI
    // ------------------------------
    string private _baseTokenURI;

    function setBaseURI(string memory newBaseURI) external onlyAdmin {
        _baseTokenURI = newBaseURI;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        if (bytes(_baseTokenURI).length == 0) {
            return "";
        }

        return string(abi.encodePacked(_baseTokenURI, _toString(tokenId)));
    }

    // uint -> string helper
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }


    // ------------------------------
    // VIEW FUNCTIONS
    // ------------------------------
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }


    // ------------------------------
    // MINTING
    // ------------------------------
    function safeMint(address to, uint256 tokenId) external onlyAdmin {
        require(!mintPaused, "Minting paused");
        require(to != address(0), "Mint to zero address");
        require(!_exists(tokenId), "Token already exists");
        require(totalSupply + 1 <= maxSupply, "Max supply reached");

        _owners[tokenId] = to;
        _balances[to] += 1;
        totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }


    // ------------------------------
    // APPROVALS
    // ------------------------------
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "Not authorized");
        require(to != owner, "Approval to current owner");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve to yourself");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    // ------------------------------
    // TRANSFERS
    // ------------------------------
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
                spender == _tokenApprovals[tokenId] ||
                _operatorApprovals[owner][spender]);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        require(ownerOf(tokenId) == from, "Incorrect owner");
        require(to != address(0), "Transfer to zero address");

        // Clear old approval
        _tokenApprovals[tokenId] = address(0);

        // Update balances
        _balances[from] -= 1;
        _balances[to] += 1;

        // Transfer ownership
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
    transferFrom(from, to, tokenId);

    // use empty bytes for compatibility
    require(
        _checkOnERC721Received(from, to, tokenId, ""),
        "ERC721: transfer to non ERC721Receiver implementer"
    );
}

// Minimal receiver check stub — returns true by default.
function _checkOnERC721Received(
    address /*from*/,
    address /*to*/,
    uint256 /*tokenId*/,
    bytes memory /*data*/
) internal pure returns (bool) {
    return true;
}

function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
    transferFrom(from, to, tokenId);

    // USE `data` so compiler will not warn
    require(
        _checkOnERC721Received(from, to, tokenId, data),
        "ERC721: transfer to non ERC721Receiver implementer"
    );
}

}
