-----------------------------
--@brief：创建protobuf对象table
--@date：2025-5-29
--@author：
-----------------------------

--[[
注意：repeated不能序列化，要arr[1]才可以
测试用例：
local msg = MakeProto1("CSMsg.TbsTroopContext")
print("k1--", msg.MasterID, msg.dir, msg.weapon.weaponId, msg.arrFaction, getmetatable(msg.arrFaction))
msg.weapon.weaponId = 101

local sub1 = msg.arrFaction:Add()
sub1.faction = 1
sub1.factionStage = 2
sub1.factionProLv = 3

local sub2 = MakeProto1("CSMsg.TFactionAdditionInfo")
sub2.faction = 11
sub2.factionStage = 22
sub2.factionProLv = 33
table.insert(msg.arrFaction, sub2)

local sub3 = msg.arrFaction:Add()
local sub33 = MakeProto1("CSMsg.TFactionAdditionInfo")
print("k2--", sub3, sub33)
sub33.faction = 111
sub33.factionStage = 222
sub33.factionProLv = 333
sub3:MergeFrom(sub33)

print("k3--", sub3)
print("1asd1=", msg, msg.weapon)
print("1asd2=", msg.weapon:ToString())
print("1asd3=", #msg.weapon:SerializeToString())
print("1asd4=", msg.arrFaction:ToString())
print("1asd5=", #msg.arrFaction[1]:SerializeToString()) --注意repeated不能序列化，要arr[1]才可以
print("1asd6=", msg:ToString())
 print("1asd7=", #msg:SerializeToString())

local str = msg:SerializeToString()
local newmsg = MakeProto1("CSMsg.TbsTroopContext")
newmsg:ParseFromString(str)
warning("newmsg=", newmsg:ToString())
print("new k1--", newmsg.MasterID, newmsg.dir, newmsg.weapon.weaponId, getmetatable(newmsg.weapon), newmsg.arrFaction, getmetatable(msg.arrFaction))
print("new k2--", newmsg.dynamicRate, newmsg.teamId, newmsg.soldierNumList, newmsg.soldierNumList.data, getmetatable(newmsg.soldierNumList))
print("new k3--", newmsg.soldierNumList:ToString(), newmsg.soldierNumList.data:ToString())
print("new k4--", #newmsg.soldierNumList:SerializeToString())
print("new k5--", #newmsg:SerializeToString())
warning("newmsg after=", newmsg:ToString())

local soldierMsg = MakeProto1("CSMsg.TSoldierNumList")
soldierMsg:ParseFromString(newmsg.soldierNumList:SerializeToString())
print("soldierMsg=", soldierMsg:ToString())
local ss1 = soldierMsg.data:Add()
ss1.lv = 1
ss1.num = 10
print("soldierMsg 1=", soldierMsg:ToString())
newmsg.soldierNumList:MergeFrom(soldierMsg)
print("soldierMsg 2=", soldierMsg:ToString())
newmsg.soldierNumList:ParseFromString(soldierMsg:SerializeToString())
print("newmsg.soldierNumList 1=", newmsg.soldierNumList:ToString())
newmsg.soldierNumList:Clear()
print("newmsg.soldierNumList 2=", newmsg.soldierNumList:ToString())
print("newmsg.soldierNumList.data=", newmsg.soldierNumList.data:ToString())
]]--

---------------------------------------- makepb -------------------------------------------
pb_methods = {}

local makepb = {
    _lpb = nil,
    type_default_val = nil,
    fieldTypes = {},
}

makepb.type_default_val = {
    ["int32"] = 0, ["uint32"] = 0, ["fixed32"] = 0, ["sfixed32"] = 0, ["sint32"] = 0,
    ["int64"] = 0, ["uint64"] = 0, ["fixed64"] = 0, ["sfixed64"] = 0, ["sint64"] = 0,
    ["double"] = 0, ["float"] = 0, ["string"] = "", ["bytes"] = "", ["bool"] = false,
}

function MakeProto(message_type)
    return makepb.New(message_type)()
end

function makepb.New(message_type)
    local function ctor()
        local obj = makepb.SetLazyDefaults({}, message_type) 
        return obj
    end
    return ctor
end

function makepb.SetLazyDefaults(obj, message_type)
    local pb = makepb._lpb
    message_type = makepb.AmendName(message_type)
    --缓存字段类型
    if makepb.fieldTypes[message_type] == nil then
        makepb.fieldTypes[message_type] = makepb.fieldTypes[message_type] or {}
        for name, number, type1, defaultval, label in pb.fields(message_type) do
            name = makepb.AmendName(name)
            makepb.fieldTypes[message_type][name] = {type1 = type1, label = label}
        end
    end
    local field_types = makepb.fieldTypes[message_type]
    local meta = {
        _message_type = message_type,
        __index = function(t, k)
            -- 优先查pb方法
            --print("SetLazyDefaults __index 1--", message_type, t, k, pb_methods[k])
            if pb_methods[k] then
                return pb_methods[k]
            end
            local info = field_types[k]
            if info == nil then
                error("not find field:", k, message_type)
                return nil
            end
            local v = rawget(t, k)
            --print("SetLazyDefaults __index 2--", t, k, v)
            if v ~= nil then
                return v
            end
            --print("SetLazyDefaults __index 3--", t, k, info.label)
            local name2, _, type2 = pb.type(info.type1)
            if info.label == "repeated" then
                v = makepb.SetLazyDefaults({}, name2)
            elseif makepb.type_default_val[info.type1] ~= nil then
                v = makepb.type_default_val[info.type1]
                --print("SetLazyDefaults __index 33--", t, k, v)
            else
                if type2 == "message" then
                    v = makepb.SetLazyDefaults({}, name2)
                    --print("SetLazyDefaults __index 34--", t, k, name2, v)
                elseif type2 == "enum" then
                    v = makepb.GetEnumDefaultVal(pb, name2)
                else
                    v = nil
                end
            end
            --print("SetLazyDefaults __index 4--", t, k, name2, v)
            rawset(t, k, v)
            return v
        end,
    }

    setmetatable(obj, meta)
    return obj
end

function makepb.AmendName(message_type)
    --修正 message_type，因为pb.fields返回的值是.CSMsg.xxx 多个.号
    local firstChar = string.sub(message_type, 1, 1)
    if firstChar == "." then
        message_type = string.gsub(message_type, "^%.", "")
    end
    return message_type
end

function makepb.GetEnumDefaultVal(pb, name)
    --10以内找下
    for i = 0, 10 do
        local val = pb.enum(name, i)
        if val and #val > 0 then
            return i
        end
    end
    --最小值不是10以内
    local defVal = nil
    for name1, number1, type1 in pb.fields(name) do
        defVal = defVal or number1
        defVal = math.min(defVal, number1)
    end
    return defVal
end

function makepb.Copy(dst, src, seen)
    if type(src) ~= "table" or type(dst) ~= "table" then
        return dst
    end
    seen = seen or {}
    if seen[src] then
        return seen[src]
    end
    dst = dst or {}
    seen[src] = dst
    for k, v in pairs(src) do
        local new_k = (type(k) == "table") and makepb.Copy(nil, k, seen) or k
        local new_v = (type(v) == "table") and makepb.Copy(nil, v, seen) or v
        dst[new_k] = new_v
    end
    return dst
end

function makepb.TableToString(tbl, indent, visited)
    indent = indent or 0
    visited = visited or {}
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    if indent > 100 then
        return string.format("%s%s", string.rep("  ", indent), "over limit\n")
    end
    if visited[tbl] then
        return string.format("%s%s", string.rep("  ", indent), "<cycle>\n")
    end
    --warning("TableToString 1--", tbl, indent)
    visited[tbl] = true
    local spaces = string.rep("  ", indent)
    local result = "{\n"
    for k, v in pairs(tbl) do
        local keyStr = tostring(k)
        local valueStr
        --print("TableToString 3--", k, v, type(v))
        if type(v) == "table" then
            valueStr = makepb.TableToString(v, indent + 1, visited)
        else
            valueStr = tostring(v)
        end
        result = string.format('%s%s  %s = %s,\n', result, spaces, keyStr, valueStr)
    end
    --warning("TableToString 4--", tbl)
    result = string.format('%s%s}', result, spaces)
    return result
end

---------------------------------------- pb_methods -------------------------------------------
function pb_methods:SerializeToString()
    local mt = getmetatable(self)
    --print("SerializeToString 1--", mt._message_type, self)
    return makepb._lpb.encode(mt._message_type, self)
end

function pb_methods:ParseFromString(data)
    local mt = getmetatable(self)
    local t = makepb._lpb.decode(mt._message_type, data)
    self = makepb.Copy(self, t)
    makepb.SetLazyDefaults(self, mt._message_type)
end

function pb_methods:Add()
    local mt = getmetatable(self)
    local msg = makepb.SetLazyDefaults({}, mt._message_type)
    table.insert(self, msg)
    --print("pb_methods:Add 1--", self, mt._message_type, msg, #self)
    return msg
end

function pb_methods:MergeFrom(from)
    local mt = getmetatable(self)
    local mtf = getmetatable(from)
    local same = mt._message_type == mtf._message_type
    if not same then
        error("pb_methods:MergeFrom failed! _message_type error", mt._message_type, mtf._message_type)
        return
    end
    --print("pb_methods:MergeFrom 1--", self, from, obj)
    self = makepb.Copy(self, from)
    --print("pb_methods:MergeFrom 2--", self, getmetatable(self), self:ToString())
end

function pb_methods:Clear()
    local mt = getmetatable(self)
    for k, v in pairs(self) do
        self[k] = nil
    end
end

function pb_methods:ToString()
    local mt = getmetatable(self)
    --print("pb_methods:ToString 1--", mt._message_type, self)
    return string.format("%s %s", mt._message_type, makepb.TableToString(self))
end

---------------------------------------- _lpb_init -------------------------------------------
function _lpb_init()
    local sofile = "../CommonLib/lpb.so"
    local open = package.loadlib(sofile, "luaopen_lpb")
    if open then
        local res = open()  -- 试试能否手动打开
        print("_lpb_init open()= ", res)
    end
    --load xx.pb file
    if string.find(package.cpath, "CommonLib/?.so") == nil then
        package.cpath = "../CommonLib/?.so;" .. package.cpath
        --print("_lpb_init set cpath--", package.cpath)
    end
    local file = io.open("../protobuf.pb", "r")
    local data = file:read("*all")
    file:close()
    makepb._lpb = require "lpb"
    local ret, val = makepb._lpb.load(data)
    assert(ret, "_lpb_init failed!")
    print("_lpb_init suc.", ret, val, makepb._lpb.type("CSMsg.TbsTroopContext"))
end
_lpb_init()

return makepb