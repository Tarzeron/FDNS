pragma solidity ^0.4.25;

contract GNS {
    
    bytes[] private _records;
    mapping (address => mapping (uint8 => uint128[])) private _recordIdsForOwnerByType;
    mapping (address => uint128[]) private _recordIdsForOwner;
    mapping (string => address) private _ownerOfName;
    mapping (address => string) private _namesOfOwner;
    mapping (bytes => uint128) private _existRawRecordsByContent;
    
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
        uint8 typeOfRcord = uint8(_rawRecord[0]);
        if(typeOfRcord != 0)
            return false;
        if(_rawRecord.length < 5)
            return false;
        if(uint32(_rawRecord.length - 5) != bytesToUint32LE(_rawRecord, 1))
            return false;
        return true;
    }
    
    function isValidIPv4Record(bytes _rawRecord) pure public returns(bool) {
        uint8 typeOfRcord = uint8(_rawRecord[0]);
        if(typeOfRcord != 1)
            return false;
        if(_rawRecord.length != 5)
            return false;
        return true;
    }
    
    function isValidIPv6Record(bytes _rawRecord) pure public returns(bool) {
        uint8 typeOfRcord = uint8(_rawRecord[0]);
        if(typeOfRcord != 2)
            return false;
        if(_rawRecord.length != 17)
            return false;
        return true;
    }
    
    function isValidDNSRecord(bytes _rawRecord) pure public returns(bool) {
        uint8 typeOfRcord = uint8(_rawRecord[0]);
        if(typeOfRcord != 3)
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
        uint8 typeOfRcord = uint8(_rawRecord[0]);
        if(typeOfRcord >= 64 && typeOfRcord <= 255)
            return true;
        if(typeOfRcord == 0)
            return isValidFDNSRecord(_rawRecord);
        else if(typeOfRcord == 1)
            return isValidIPv4Record(_rawRecord);
        else if(typeOfRcord == 2)
            return isValidIPv6Record(_rawRecord);
        else if(typeOfRcord == 3)
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
        uint128 recordIndex = uint128(_records.push(_rawRecord)-1);
        _recordIdsForOwner[msg.sender].push(recordIndex) ;
        
        _existRawRecordsByContent!!!!!!!!!!!
        _recordIdsForOwnerByType!!!!!!!!!!!
    }
    
    function removeRecordByIndex(uint128 _recordIndex) public {
        uint128[] storage recordIdsForOwner = _recordIdsForOwner[msg.sender];
        bool found=false;
        for(uint128 i=0;i<recordIdsForOwner.length;i++) {
            if(found)
                recordIdsForOwner[i-1] = recordIdsForOwner[i];
            else if(recordIdsForOwner[i] == _recordIndex){
                found = true;
            }
        }
        recordIdsForOwner.length--;
    }
    
    function getRawRecordById(uint128 _recordIndex) view public returns(bytes){
        require(_recordIndex>=0 && _recordIndex<_records.length);
        return _records[_recordIndex];
    }
    
    function getRecordsList(string _name, 
            bool _useFilter, 
            uint8 _typeOfRecord) 
            view 
            public 
            onlyExistName(_name)
            returns(uint128[]){
        address addressOfOwner = _ownerOfName[_name];
        if(_useFilter)
            return _recordIdsForOwnerByType[addressOfOwner][_typeOfRecord];
        return _recordIdsForOwner[addressOfOwner];
    }
    
    function isNameExist(string _name) view public returns(bool){
        return _ownerOfName[_name] != 0;
    }
    
    
    //--------------------------------------------------------------------
    function stringToHexHelper(string what) pure public returns(bytes) {
        return bytes(what);
    }
}
