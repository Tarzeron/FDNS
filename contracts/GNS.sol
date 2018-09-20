pragma solidity ^0.4.25;

contract GNS {
    
    bytes[] private _records;
    mapping (address => mapping (uint8 => uint128[])) private _recordIdsForOwnerByType;
    mapping (address => uint128[]) private _recordIdsForOwner;
    mapping (string => address) private _ownerOfName;
    // mapping (address => string) private _namesOfOwner;
    mapping (bytes => uint128) private _existRawRecordsByContent;
    
    constructor() public{
        _records.length++;
    }
    
    modifier onlyOwnerOfName(string _name) {
        address owner = _ownerOfName[_name];
        require(owner == 0 || owner == msg.sender);
        _;
    }
    
    modifier onlyExistName(string _name) {
        require(isNameExist(_name));
        _;
    }
    
    function isValidName(string _name) pure public returns(bool) {
        bytes memory nameInByteArray = bytes(_name);
        for(uint128 i=0; i<nameInByteArray.length; i++)
            if(nameInByteArray[i] == '.')
                return false;
        return true;
    }
    
    function isValidString(bytes _str, uint32 _offset, uint32 _length) pure public returns(bool) {
        if(_str.length <= _offset+_length)
            return false;
        for(uint128 i=_offset; i<_length; i++)
            if(_str[i] == 0)
                return false;
        return true;
    }
    
    function bytesToUint32LE(bytes _what, uint32 _offset) pure public returns(uint32) {
        require(_what.length >= _offset + 4);
        return uint32(_what[_offset]) 
            | (uint32(_what[_offset + 1])<<8) 
            | (uint32(_what[_offset + 2])<<16) 
            | (uint32(_what[_offset + 3])<<24);
    }
    
    function isValidFDNSRecord(bytes _rawRecord) pure public returns(bool) {
        uint8 typeOfRecord = uint8(_rawRecord[0]);
        if(typeOfRecord != 0)
            return false;
        if(_rawRecord.length < 5)
            return false;
        if(uint32(_rawRecord.length - 5) != bytesToUint32LE(_rawRecord, 1))
            return false;
        return true;
    }
    
    function isValidIPv4Record(bytes _rawRecord) pure public returns(bool) {
        uint8 typeOfRecord = uint8(_rawRecord[0]);
        if(typeOfRecord != 1)
            return false;
        if(_rawRecord.length != 5)
            return false;
        return true;
    }
    
    function isValidIPv6Record(bytes _rawRecord) pure public returns(bool) {
        uint8 typeOfRecord = uint8(_rawRecord[0]);
        if(typeOfRecord != 2)
            return false;
        if(_rawRecord.length != 17)
            return false;
        return true;
    }
    
    function isValidDNSRecord(bytes _rawRecord) pure public returns(bool) {
        uint8 typeOfRecord = uint8(_rawRecord[0]);
        if(typeOfRecord != 3)
            return false;
        if(!isValidString(_rawRecord, 1, uint32(_rawRecord.length - 1)))
            return false;
        return true;
    }
    
    /**
     * If type of protocol not in range for custom or not unknow type, the  function the return false
     */
    function isValidRecord(bytes _rawRecord) pure public returns(bool) {
        if(_rawRecord.length <= 1)
            return false;
        uint8 typeOfRecord = uint8(_rawRecord[0]);
        if(typeOfRecord >= 64 && typeOfRecord <= 255)
            return true;
        if(typeOfRecord == 0)
            return isValidFDNSRecord(_rawRecord);
        else if(typeOfRecord == 1)
            return isValidIPv4Record(_rawRecord);
        else if(typeOfRecord == 2)
            return isValidIPv6Record(_rawRecord);
        else if(typeOfRecord == 3)
            return isValidDNSRecord(_rawRecord);
        return false;
    }
    
    function getOwnerForName(string _name) view public returns(address) {
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
        if(recordIndex>0){
            uint128[] memory recByType = _recordIdsForOwnerByType[msg.sender][typeOfRecord];
            bytes32 hash = keccak256(_rawRecord);
            for(uint128 i=0;i<recByType.length;i++)
                if(keccak256(_records[recByType[i]]) == hash)
                    revert();
        }
        if (recordIndex==0) {
            recordIndex = uint128(_records.push(_rawRecord)-1);
            _existRawRecordsByContent[_rawRecord] =recordIndex;
        }
        if(_ownerOfName[_name]==0)
            _ownerOfName[_name]=msg.sender;
        _recordIdsForOwner[msg.sender].push(recordIndex);
        _recordIdsForOwnerByType[msg.sender][typeOfRecord].push(recordIndex);
    }
    
    function removeFirstElementInArrayByValue(uint128[] storage _where, uint128 _what) private {
        for(uint128 i=0;i<_where.length;i++) {
            if(_where[i] == _what){
                if(i+1<_where.length)
                    _where[i] = _where[_where.length-1];
                _where.length--;
                break;
            }
        }
    }
    
    function removeRecordById(
            string _name,
            uint128 _recordId) 
            onlyExistName(_name)
            onlyOwnerOfName(_name)
            public {
        removeFirstElementInArrayByValue(_recordIdsForOwner[msg.sender], _recordId);
        uint8 typeOfRecord = uint8(_records[_recordId][0]);
        removeFirstElementInArrayByValue(_recordIdsForOwnerByType[msg.sender][typeOfRecord], _recordId);
        if(_recordIdsForOwner[msg.sender].length == 0)
            _ownerOfName[_name] = 0;//give freedom to a name?!
    }
    
    function removeRecordByValue(
            string _name, 
            bytes _rawRecord) 
            onlyExistName(_name)
            onlyOwnerOfName(_name)
            public {
        uint128 recordIndex = _existRawRecordsByContent[_rawRecord];
        if(recordIndex == 0)
            revert();
        removeRecordById(_name, recordIndex);
    }
    
    function getRawRecordById(uint128 _recordId) view public returns(bytes){
        require(_recordId>=0 && _recordId<_records.length);
        return _records[_recordId];
    }
    
    function getRecordsList(string _name) 
            view 
            public 
            onlyExistName(_name)
            returns(uint128[]){
        address addressOfOwner = _ownerOfName[_name];
        return _recordIdsForOwner[addressOfOwner];
    }
    
    function getRecordsList(string _name, 
            uint8 _typeOfRecord) 
            view 
            public 
            onlyExistName(_name)
            returns(uint128[]){
        address addressOfOwner = _ownerOfName[_name];
        return _recordIdsForOwnerByType[addressOfOwner][_typeOfRecord];
    }
    
    function isNameExist(string _name) view public returns(bool){
        return _ownerOfName[_name] != 0;
    }
    
    
    //--------------------------------------------------------------------
    function stringToHexHelper(string what) pure public returns(bytes) {
        return bytes(what);
    }
}
