pragma solidity 0.4.25;

import "./IPlayerBase.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./ERC165.sol";
import "./Governable.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";
import "./ERC721Metadata.sol";
import "./IERC721Full.sol";
import "./ERC721Full.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./PlayerBasePicing.sol";
import "./PlayerCardBase.sol";

/**
 * @title CrickethPlayerCardNFT
 * @dev Implements batch operations on PlayerCards
 */
contract CrickethPlayerCardNFT is ERC721Full, PlayerCardBase {
    string public NAME = "Cricketh";
    string public SYMBOL = "CRICETH";

    event PlayerCardCreated(address _owner, uint _playerCardIndex);

    constructor() ERC721Full(NAME, SYMBOL) public {

    }

    /**
     * @dev Creates a new PlayerCard
     * @param _playerIds - IDs of the players
     *                     See the playerBase Contract for more info
     * @param _pcts - Respective percentages of the playerIDs to be created
     * @return _playerCardId - Token ID for the newly generated playerCard
     **/
    function createPlayerCard(uint[3] _playerIds, uint[3] _pcts) public whenNotPaused returns(uint) {
        require (_playerIds.length > 0 && _pcts.length > 0);

        uint _playerCardId = _createPlayerCard(_playerIds, _pcts);

        _mint(msg.sender, _playerCardId);

        emit PlayerCardCreated(msg.sender, _playerCardId);

        return _playerCardId;
    }

    /**
    * @dev Transfer a playerCard token from msg.sender
    * @param to : the address to which the card will be transferred
    * @param id : the id of the card to be transferred
    **/
    function transfer(address to, uint id) public payable {
        require(msg.sender == ownerOf(id));
        require(to != address(0));

        transferFrom(msg.sender, to, id);
    }

    /**
    * @dev Facilitates batch creation of PlayerCards
    * @notice Batch Create PlayerCards
    **/
    function batchCreatePlayerCards(uint[3][] _playerIds, uint[3][] _pcts) public whenNotPaused {
        require (_playerIds.length > 0 && _pcts.length > 0);

        for(uint i=0; i<_playerIds.length; i++) {
            uint _playerCardId = _createPlayerCard(_playerIds[i], _pcts[i]);

            _mint(msg.sender, _playerCardId);

            emit PlayerCardCreated(msg.sender, _playerCardId);
        }
    }

    // transfer balance to owner
	function withdrawEther(uint256 amount) public {
		if(msg.sender != owner) revert();
		owner.transfer(amount);
	}

	function() public payable {}
}