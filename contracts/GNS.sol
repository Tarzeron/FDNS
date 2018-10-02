import "./GNSlib.sol";

pragma solidity ^0.4.24;

contract GNS is GNSlib{

    /*  STORAGE
    */

    bytes[] private _records;
    mapping(string => mapping(uint8 => uint128[])) private _recordIdsForNameByType;
    mapping(string => uint128[]) private _recordIdsForName;
    mapping(string => address) private _ownerOfName;
    mapping(address => string) private _nameOfOwner;
    mapping(bytes => uint128) private _existRawRecordsByContent;

    /*  CONSTRUCTOR
    */

    constructor() public{
        _records.length++;
    }

    /*  MODIFIERS
    */

    /** @notice Verifies is sender address is owner of record name
    */
    modifier onlyOwnerOfName(string _name) {
        address owner = _ownerOfName[_name];
        require(owner == 0 || owner == msg.sender);
        _;
    }

    /** @notice Verifies is record name exists
    */
    modifier onlyExistName(string _name) {
        require(isNameExist(_name));
        _;
    }

    /*  PUBLIC
    */

    function getOwnerForName(string _name) view public returns (address) {
        return _ownerOfName[_name];
    }

    function createRecord(
        string _name,
        bytes _rawRecord)
    onlyOwnerOfName(_name)
    public {
        require(isValidRecord(_rawRecord));
        uint128 recordIndex = _existRawRecordsByContent[_rawRecord];
        uint8 typeOfRecord = uint8(_rawRecord[0]);
        if (recordIndex > 0) {
            uint128[] memory recByType = _recordIdsForNameByType[_name][typeOfRecord];
            bytes32 hash = keccak256(_rawRecord);
            for (uint128 i = 0; i < recByType.length; i++)
                if (keccak256(_records[recByType[i]]) == hash)
                    revert();
        }
        if (recordIndex == 0) {
            recordIndex = uint128(_records.push(_rawRecord) - 1);
            _existRawRecordsByContent[_rawRecord] = recordIndex;
        }
        if (_ownerOfName[_name] == 0) {
            require(isValidName(_name));
            if (bytes(_nameOfOwner[msg.sender]).length > 0)
                revert();
            _nameOfOwner[msg.sender] = _name;
            _ownerOfName[_name] = msg.sender;
        }
        _recordIdsForName[_name].push(recordIndex);
        _recordIdsForNameByType[_name][typeOfRecord].push(recordIndex);
    }

    function removeRecordById(
        string _name,
        uint128 _recordId)
    onlyExistName(_name)
    onlyOwnerOfName(_name)
    public {
        removeFirstElementInArrayByValue(_recordIdsForName[_name], _recordId);
        uint8 typeOfRecord = uint8(_records[_recordId][0]);
        removeFirstElementInArrayByValue(_recordIdsForNameByType[_name][typeOfRecord], _recordId);
        if (_recordIdsForName[_name].length == 0) {
            _ownerOfName[_name] = 0;
            //give freedom to a name?!
            _nameOfOwner[msg.sender] = "";
        }
    }

    function removeRecordByValue(
        string _name,
        bytes _rawRecord)
    onlyExistName(_name)
    onlyOwnerOfName(_name)
    public {
        uint128 recordIndex = _existRawRecordsByContent[_rawRecord];
        if (recordIndex == 0)
            revert();
        removeRecordById(_name, recordIndex);
    }

    function getRawRecordById(uint128 _recordId) view public returns (bytes){
        require(_recordId >= 0 && _recordId < _records.length);
        return _records[_recordId];
    }

    function getRecordsList(string _name)
    view
    public
    onlyExistName(_name)
    returns (uint128[]){
        return _recordIdsForName[_name];
    }

    function getRecordsList(string _name,
        uint8 _typeOfRecord)
    view
    public
    onlyExistName(_name)
    returns (uint128[]){
        return _recordIdsForNameByType[_name][_typeOfRecord];
    }

    function isNameExist(string _name) view public returns (bool){
        return _ownerOfName[_name] != 0;
    }

    /*  PRIVATE
    */

    function removeFirstElementInArrayByValue(uint128[] storage _where, uint128 _what) private {
        for (uint128 i = 0; i < _where.length; i++) {
            if (_where[i] == _what) {
                if (i + 1 < _where.length)
                    _where[i] = _where[_where.length - 1];
                _where.length--;
                break;
            }
        }
    }

    /*
    "name"
    "name1"
    "name2"
    -------create valid---------
    "name",0x0000000003313233
    "name",0x0000000003312e33
    "name",0x0000000003714233
    "name1",0x0000000003714233
    "name",0x01ffffffaa
    "name",0x01ffbbffaa
    "name",0x02ffbbffaaffbbffaaffbbffaaffbbffaa
    "name",0x03313233
    "name",0x03313333
    -------filter valid---------
    "name",0x00
    "name",0x01
    "name",0x02
    "name",0x03
    "name1",0x00
    "name2",0x00
    ---------removing-----
    "name",5
    "name",0x01ffbbffaa
    ---------invalid---------
    "na.me",0x0000000003313233
    "name",0x00000000033132
    "name",0x01ffffaa
    "name",0x02ffbbffaaffbbffaaffbbffaaffbbff
    "name",0x03
    "name22",5
    */
}
