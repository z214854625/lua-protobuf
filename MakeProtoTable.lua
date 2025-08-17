-----------------------------
--@brief：创建protobuf对象table
--@date：2025-5-29
--@author：
-----------------------------

--[[
注意：repeated不能序列化，要arr[1]才可以
测试用例：
function p_test1()
    local msg = MakeProto1("CSMsg.TbsTroopContext")
    print("k1--", msg.kkkk, msg.MasterID, msg.dir, msg.weapon.weaponId, msg.haloids, msg.arrFaction, getmetatable(msg.arrFaction))
    msg.weapon.weaponId = 101
    local sub1 = msg.arrFaction:add()
    sub1.faction = 1
    sub1.factionStage = 2
    sub1.factionProLv = 3

    local sub2 = MakeProto1("CSMsg.TFactionAdditionInfo")
    sub2.faction = 11
    sub2.factionStage = 22
    sub2.factionProLv = 33
    table.insert(msg.arrFaction, sub2)

    local sub3 = msg.arrFaction:add()
    local sub33 = MakeProto1("CSMsg.TFactionAdditionInfo")
    print("k2--", sub3, sub33)
    sub33.faction = 111
    sub33.factionStage = 222
    sub33.factionProLv = 333
    sub3:MergeFrom(sub33)
    print("k3--", sub3)

    table.insert(msg.haloids, 1)
    table.insert(msg.haloids, 2)
    table.insert(msg.haloids, 3)

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
    local ss1 = soldierMsg.data:add()
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

    local t1 = {}
    for i, v in ipairs(newmsg.arrFaction) do
        print("arrFaction mt--", i, getmetatable(v))
        t1[i] = MakeProto1("CSMsg.TFactionAdditionInfo")
        t1[i]:MergeFrom(v)
    end

    local newmsg3 = MakeProto1("CSMsg.TbsTroopContext")
    for _, v in ipairs(t1) do
        local s = newmsg3.arrFaction:add()
        s:MergeFrom(v)
    end
    print("newmsg3=", newmsg3:ToString())

    --parse and mergefrom
    local msgnew55 = MakeProto1("CSMsg.TbsTroopContext")
    msgnew55:MergeFrom(newmsg)

    local soldierMsg55 = MakeProto1("CSMsg.TSoldierNumList")
    soldierMsg55:ParseFromString(msgnew55.soldierNumList:SerializeToString())
    print("soldierMsg55=", soldierMsg55:ToString())
    local ss55 = soldierMsg55.data:add()
    ss55.lv = 1
    ss55.num = 10
    print("soldierMsg55 1=", soldierMsg55:ToString())
    msgnew55.soldierNumList:MergeFrom(soldierMsg55)
    print("soldierMsg55 2=", soldierMsg:ToString())
    msgnew55.soldierNumList:ParseFromString(soldierMsg:SerializeToString())
    print("msgnew55.soldierNumList 1=", msgnew55.soldierNumList:ToString())
    msgnew55.soldierNumList:Clear()
    print("msgnew55.soldierNumList 2=", msgnew55.soldierNumList:ToString())
    print("msgnew55.soldierNumList.data=", msgnew55.soldierNumList.data:ToString())

    local t55 = {}
    for i, v in ipairs(msgnew55.arrFaction) do
        print("arrFaction 55 mt--", i, getmetatable(v))
        t55[i] = MakeProto1("CSMsg.TFactionAdditionInfo")
        t55[i]:MergeFrom(v)
    end

    local newmsg33 = MakeProto1("CSMsg.TbsTroopContext")
    for _, v in ipairs(t55) do
        local s = newmsg33.arrFaction:add()
        s:MergeFrom(v)
    end
    print("newmsg33=", newmsg33:ToString())
end
p_test1()

function p_test2()
    local msg = MakeProto1("CSMsg.TDBAcronPubPerson")
    msg.curTaskSID = 123
    msg.refreshTime = 1
    msg.superRefreshTime = 123
    msg.lastResetOpTime = 1
    msg.helpTimes = 123
    msg.robTimes = 1

    local s1 = msg.tasks:add()
    s1.taskSID = 1
    s1.taskID = 2
    s1.doneTime = 3
    s1.sandboxSid = 4
    s1.pos.x = 5
    s1.pos.y = 6
    s1.helpDbid = 7
    s1.rewarded = 8
    local s2 = msg.tasks:add()
    s2.taskSID = 11
    s2.taskID = 22
    s2.doneTime = 33
    s2.sandboxSid = 44
    s2.pos.x = 55
    s2.pos.y = 66
    s2.helpDbid = 77
    s2.rewarded = 88

    local s11 = msg.records:add()
    s11.dbid = 111
    s11.name = "222"
    s11.faceID = 333
    s11.frameID = 444
    s11.allianceShortName = "555"
    s11.occurTime = 666
    s11.taskSID = 777
    local s22 = msg.records:add()
    s22.dbid = 1111
    s22.name = "2222"
    s22.faceID = 3333
    s22.frameID = 4444
    s22.allianceShortName = "5555"
    s22.occurTime = 6666
    s22.taskSID = 7777

    local str = msg:SerializeToString()
    local msgnew = MakeProto1("CSMsg.TDBAcronPubPerson")
    msgnew:ParseFromString(str)

    local t1 = {}
    for i, v in ipairs(msgnew.tasks) do
        t1[i] = MakeProto1("CSMsg.TAcronPubTaskItem")
        t1[i]:MergeFrom(v)
    end

    local t2 = {}
    for i, v in ipairs(msgnew.records) do
        t2[i] = MakeProto1("CSMsg.TAcronPubTaskRecordItem")
        t2[i]:MergeFrom(v)
    end
    
    local ntf = MakeProto1("CSMsg.TMSG_ACORNPUB_INFO_NTF")
    for _, v in ipairs(t1) do
        local s = ntf.data.tasks:add()
        s:MergeFrom(v)
    end
    print("ntf=", ntf:ToString())

    for i, v in ipairs(t2) do
        local s = MakeProto1("CSMsg.TAcronPubTaskRecordItem")
        s:MergeFrom(v)
        print("TAcronPubTaskRecordItem --", i, s:ToString())
    end
    
    ------------------------------
    local msg12 = MakeProto1("CSMsg.TDBAcronPubPerson")
    msg12.curTaskSID = 123
    msg12.refreshTime = 1
    msg12.superRefreshTime = 123
    msg12.lastResetOpTime = 1
    msg12.helpTimes = 123
    msg12.robTimes = 1
    local s12 = msg12.tasks:add()
    s12.taskSID = 1
    s12.taskID = 2
    s12.doneTime = 3
    s12.sandboxSid = 4
    s12.pos.x = 5
    s12.pos.y = 6
    s12.helpDbid = 7
    s12.rewarded = 8
    local str12 = msg12:SerializeToString()
    local msgnew12 = MakeProto1("CSMsg.TDBAcronPubPerson")
    msgnew12:ParseFromString(str12)
    for k, v in pairs(msgnew12.records) do
        print("p_test2--", k, v)
    end
    print("msgnew12.records=", msgnew12.records:ToString())
    print("msgnew12=", msgnew12:ToString())
    print("msg12.tasks serialize=", #msg12.tasks:SerializeToString()) --预期0
    local msgnew13 = MakeProto1("CSMsg.TDBAcronPubPerson")
    msgnew13.tasks:MergeFrom(msg12.tasks)
    print("msgnew13.tasks SerializeToString=", msgnew13.tasks:SerializeToString()) --预期0
    print("msgnew13.tasks ToString=", msgnew13.tasks:ToString())
    print("msgnew13 SerializeToString=", msgnew13:SerializeToString())
    print("msgnew13=", msgnew13:ToString())
end
p_test2()

function yali_ceshi()
    gMyClock = nil
    local testCostTime = function(desc, tick)
        if not gMyClock then
            gMyClock = os.clock()
        end
        if tick then
            gMyClock =  tick
        end
        local curTick = os.clock()
        local diff = curTick - gMyClock
        desc = desc or "testCostTime------------->"
        print(desc, "  curTick:", curTick, "  cost:",diff)
        gMyClock = curTick
        return diff
    end
    
    local typeStr = common_new_pb.CityTroop
    local dbid  = 136801
    local index = 1
    local key = RemoteSaveTroop_GetTroopKey(typeStr, dbid)
    local simpleField = "simple_" .. index
    local cmd = {"HMGET", key, simpleField}
    AutoRedisPipeCmd(cmd, function(data, err)
        if data[1] == nil or data[1] == "" then
            return
        end
        error(", #data[1]", #data[1], data[1])
        
        -- LuaPB老方式
            local pb_target_Lua = city_pb.TCityBattleLineUp()
            pb_target_Lua:ParseFromString(data[1])
        -- C++PB
            local pb_target_C = MakeProto1("CSMsg.TCityBattleLineUp")
            pb_target_C:ParseFromString(data[1])
        
        local loopTimes =  100000
        -- LuaPB
        testCostTime("SerializeToString start------------> loopTimes:", loopTimes, " data size=", #data[1])
        print("对比测试下LuaPB和C++PB的SerializeToString效率")
        for i = 1, loopTimes do
        local str = pb_target_Lua:SerializeToString()
        --pb_target1:ParseFromString(data[1])
        end
    
        local LuaPBCost = testCostTime("LuaPB SerializeToString Cost------------> loopTimes:"..loopTimes)
        -- C++PB
        for i = 1, loopTimes do
            local str = pb_target_C:SerializeToString()
            --pb_target:ParseFromString(data[1])
        end
    
        local CPBCost = testCostTime("C++PB SerializeToString Cost------------> loopTimes:"..loopTimes)
        print("SerializeToString LuaPB Cost:",LuaPBCost, " CPBCost:", CPBCost, " LuaPBCost/CPBCost:", LuaPBCost/CPBCost)
        
        print("对比测试下LuaPB和C++PB的ParseFromString效率")
        --LuaPB ParseFromString
        for i = 1, loopTimes do
            pb_target_Lua:ParseFromString(data[1])
        end
        LuaPBCost = testCostTime("LuaPB ParseFromString Cost------------> loopTimes:"..loopTimes)
        -- C++PB  ParseFromString
        for i = 1, loopTimes do
            pb_target_C:ParseFromString(data[1])
        end
        CPBCost = testCostTime("C++PB ParseFromString Cost------------> loopTimes:"..loopTimes)
        print("ParseFromString  LuaPB Cost:",LuaPBCost, " CPBCost:", CPBCost, " LuaPBCost/CPBCost:", LuaPBCost/CPBCost)
    end, enGameSvcRedisDest, dbid)gMyClock = nil
    local testCostTime = function(desc, tick)
        if not gMyClock then
            gMyClock = os.clock()
        end
        if tick then
            gMyClock =  tick
        end
        local curTick = os.clock()
        local diff = curTick - gMyClock
        desc = desc or "testCostTime------------->"
        print(desc, "  curTick:", curTick, "  cost:",diff)
        gMyClock = curTick
        return diff
    end
    
    local typeStr = common_new_pb.CityTroop
    local dbid  = 136801
    local index = 1
    local key = RemoteSaveTroop_GetTroopKey(typeStr, dbid)
    local simpleField = "simple_" .. index
    local cmd = {"HMGET", key, simpleField}
    AutoRedisPipeCmd(cmd, function(data, err)
        if data[1] == nil or data[1] == "" then
            return
        end
        error(", #data[1]", #data[1], data[1])
        
        -- LuaPB老方式
            local pb_target_Lua = city_pb.TCityBattleLineUp()
            pb_target_Lua:ParseFromString(data[1])
        -- C++PB
            local pb_target_C = MakeProto1("CSMsg.TCityBattleLineUp")
            pb_target_C:ParseFromString(data[1])
        
        local loopTimes =  100000
        -- LuaPB
        testCostTime("SerializeToString start------------> loopTimes:", loopTimes, " data size=", #data[1])
        print("对比测试下LuaPB和C++PB的SerializeToString效率")
        for i = 1, loopTimes do
        local str = pb_target_Lua:SerializeToString()
        --pb_target1:ParseFromString(data[1])
        end
    
        local LuaPBCost = testCostTime("LuaPB SerializeToString Cost------------> loopTimes:"..loopTimes)
        -- C++PB
        for i = 1, loopTimes do
            local str = pb_target_C:SerializeToString()
            --pb_target:ParseFromString(data[1])
        end
    
        local CPBCost = testCostTime("C++PB SerializeToString Cost------------> loopTimes:"..loopTimes)
        print("SerializeToString LuaPB Cost:",LuaPBCost, " CPBCost:", CPBCost, " LuaPBCost/CPBCost:", LuaPBCost/CPBCost)
        
        print("对比测试下LuaPB和C++PB的ParseFromString效率")
        --LuaPB ParseFromString
        for i = 1, loopTimes do
            pb_target_Lua:ParseFromString(data[1])
        end
        LuaPBCost = testCostTime("LuaPB ParseFromString Cost------------> loopTimes:"..loopTimes)
        -- C++PB  ParseFromString
        for i = 1, loopTimes do
            pb_target_C:ParseFromString(data[1])
        end
        CPBCost = testCostTime("C++PB ParseFromString Cost------------> loopTimes:"..loopTimes)
        print("ParseFromString  LuaPB Cost:",LuaPBCost, " CPBCost:", CPBCost, " LuaPBCost/CPBCost:", LuaPBCost/CPBCost)
    end, enGameSvcRedisDest, dbid)
end
--yali_ceshi()
]]--

---------------------------------------- makepb -------------------------------------------
local pb_methods = {}

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
    if message_type == nil then
        error("makepb.SetLazyDefaults message_type nil")
        return obj
    end
    local pb = makepb._lpb
    message_type = makepb.AmendName(message_type)
    local field_types = makepb.GetFieldTypes(message_type)

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
                --error("not find field:", k, message_type)
                return nil
            end
            local v = rawget(t, k)
            local name2, _, type2 = pb.type(info.type1)
            --print("SetLazyDefaults __index 2--", t, k, v, info.type1, info.label, type2)
            if v ~= nil then
                if info.label == "repeated" and type(v) == "table" then
                    for i, elem in ipairs(v) do
                        --print("SetLazyDefaults __index 21--", t, k, info.type1, i)
                        v[i] = makepb.SetLazyDefaults(elem, name2)
                    end
                    --v = makepb.SetLazyDefaults(v, name2)
                elseif type(v) == "table" then
                    v = makepb.SetLazyDefaults(v, name2)
                else
                    --do nothing
                end
                return v
            end
            --print("SetLazyDefaults __index 3--", t, k, info.type1, info.label, type2)
            if info.label == "repeated" then
                --print("SetLazyDefaults __index 31--", t, k)
                v = (type2 == "message") and setmetatable({}, makepb.MakeRepeatedMeta(name2)) or {}
                --v = (type2 == "message") and makepb.SetLazyDefaults({}, name2) or {}
            else
                if type2 == "message" then
                    --print("SetLazyDefaults __index 32--", t, k)
                    v = makepb.SetLazyDefaults({}, name2)
                elseif type2 == "enum" then
                    --print("SetLazyDefaults __index 33--", t, k)
                    v = makepb.GetEnumDefaultVal(pb, name2)
                else
                    --print("SetLazyDefaults __index 34--", t, k)
                    v = makepb.type_default_val[info.type1]
                end
            end
            --print("SetLazyDefaults __index 4--", t, k, name2, type2, v)
            rawset(t, k, v)
            return v
        end,
    }

    setmetatable(obj, meta)
    return obj
end

function makepb.LazyMetaWrapper(obj, message_type)
    local pb = makepb._lpb
    local field_types = makepb.GetFieldTypes(message_type)
    local wrapper = { _obj = obj }
    local meta = {
        _message_type = message_type,

        __index = function(t, k)
            --print("LazyMetaWrapper 1--", k, message_type)
            --pb methods
            if pb_methods[k] then
                return pb_methods[k]
            end
            local v = t._obj[k]
            local info = field_types[k]
            if info == nil then
                --error("LazyMetaWrapper field_types info nil", k, message_type)
                return v
            end
            print("LazyMetaWrapper 2--", k, v, message_type)
            -- value nil
            local name2, _, type2 = pb.type(info.type1)
            if v == nil then
                --print("LazyMetaWrapper 3--", k, v, message_type, name2, type2, info.label)
                if info.label == "repeated" then
                    --v = (type2 == "message") and makepb.SetMeta({}, name2) or {}
                    v = (type2 == "message") and setmetatable({}, makepb.MakeRepeatedMeta(name2)) or {}
                else
                    if type2 == "message" then
                        v = makepb.SetMeta({}, name2)
                    elseif type2 == "enum" then
                        v = makepb.GetEnumDefaultVal(pb, name2)
                    else
                        v = makepb.type_default_val[info.type1]
                    end
                end
                t._obj[k] = v
                return v
            end
            --have value
            if type(v) == "table" and not getmetatable(v) then
                --print("LazyMetaWrapper 4--", k, v, message_type, name2, type2)
                if type2 == "message" then
                    if info.label == "repeated" then
                        for i, elem in ipairs(v) do
                            v[i] = makepb.SetMeta(elem, name2)
                        end
                        t._obj[k] = v
                    else
                        v = makepb.SetMeta(v, name2)
                        t._obj[k] = v
                    end
                end
            end
            return v
        end,
        __newindex = function(t, k, v)
            --print("LazyMetaWrapper __newindex 1--", t, t._obj, k, v, message_type)
            t._obj[k] = v
        end,
        __pairs = function(t)
            --return pairs(t._obj) --stack overflow
            --print("LazyMetaWrapper __pairs 1--", t, t._obj, message_type)
            return next, t._obj, nil
        end,
        __ipairs = function(t)
            --return ipairs(t._obj)
            --print("LazyMetaWrapper __ipairs 1--", t, t._obj, message_type)
            local iter = function(a, i)
                --print("__ipairs 2--", t, t._obj, i, message_type)
                i = i + 1
                local v = a[i]
                if v ~= nil then
                    return i, v
                end
            end
            return iter, t._obj, 0
        end
    }

    setmetatable(wrapper, meta)
    return wrapper
end

function makepb.MakeRepeatedMeta(repeated_message_type)
    local repeated_meta = {
        _message_type = repeated_message_type,

        __index = function(t, k)
            --print("MakeRepeatedMeta --", t, k, repeated_message_type, type(k))
            if pb_methods[k] then
                return pb_methods[k]
            end
            if type(k) == "number" then
                return rawget(t, k)
            end
            return nil
        end,
        __newindex = function(t, k, v)
            rawset(t, k, v)
        end,
        __pairs = function(t)
            return next, t, nil
        end,
        __ipairs = function(t)
            local iter = function(a, i)
                i = i + 1
                local v = a[i]
                if v ~= nil then
                    return i, v
                end
            end
            return iter, t, 0
        end,
    }
    return repeated_meta
end

function makepb.SetMeta(obj, message_type)
    if type(obj) ~= "table" then
        return obj
    end
    if message_type == nil then
        warning("makepb.SetMeta message_type nil")
        return obj
    end
    --print("makepb.SetMeta 1--", message_type)
    local pb = makepb._lpb
    local mt = getmetatable(obj)
    if mt == nil then
        obj = makepb.SetLazyDefaults(obj, message_type)
    end
    local field_types = makepb.GetFieldTypes(message_type)
    for k, info in pairs(field_types) do
        repeat
            local v = obj[k]
            if v == nil then
                error("makepb.SetMeta val nil", message_type, k)
                break
            end
            --非message/repeated
            if makepb.type_default_val[info.type1] ~= nil then
                --print("makepb.SetMeta 11--", message_type, k, info.type1)
                break
            end
            local name2, _, type2 = pb.type(info.type1)
            --print("makepb.SetMeta 2--", message_type, k, info.type1, info.label, type2)
            if info.label == "repeated" and type(v) == "table" then
                for i, elem in ipairs(v) do
                    --print("makepb.SetMeta 3--", message_type, k, i, name2)
                    v[i] = makepb.SetMeta(elem, name2)
                end
            else
                if type(v) == "table" then
                    --print("makepb.SetMeta 4--", message_type, k, i, name2)
                    obj[k] = makepb.SetMeta(v, name2)
                end
            end
        until true
    end
    return obj
end

function makepb.GetFieldTypes(message_type)
    --print("makepb.GetFieldTypes 1--", message_type)
    --缓存字段类型
    if makepb.fieldTypes[message_type] == nil then
        makepb.fieldTypes[message_type] = makepb.fieldTypes[message_type] or {}
        for name, number, type1, defaultval, label in makepb._lpb.fields(message_type) do
            --print("makepb.GetFieldTypes 2--", name, number, type1, defaultval, label)
            name = makepb.AmendName(name)
            makepb.fieldTypes[message_type][name] = {type1 = type1, label = label}
        end
    end
    return makepb.fieldTypes[message_type]
end

function makepb.AmendName(message_type)
    if message_type == nil then
        error("makepb.AmendName message_type nil")
        return message_type
    end
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
    return makepb._lpb.encode(mt._message_type, self._obj or self)
end

function pb_methods:ParseFromString(data)
    local mt = getmetatable(self)
    local t = makepb._lpb.decode(mt._message_type, data)
    --print("makepb.ParseFromString 0--", self, mt._message_type)
    --t = makepb.SetMeta(t, mt._message_type)
    --makepb.Copy(self, t)
    local wrapper = makepb.LazyMetaWrapper(t, mt._message_type)
    self:Clear()
    self._obj = wrapper._obj
    setmetatable(self, getmetatable(wrapper))
    --print("makepb.ParseFromString 1--", self, mt, mt._message_type, getmetatable(self))
end

function pb_methods:add()
    local mt = getmetatable(self)
    --print("pb_methods:add 1--", self, mt._message_type)
    local msg = makepb.SetLazyDefaults({}, mt._message_type)
    --print("pb_methods:add 2--", self, mt._message_type, msg, #self)
    table.insert(self, msg)
    return msg
end

function pb_methods:MergeFrom(from)
    local mt = getmetatable(self)
    local mtf = getmetatable(from)
    if mt == nil or mtf == nil then
        error("pb_methods:MergeFrom mt nil", mt and mt._message_type or nil, mtf and mtf._message_type or nil, debug.traceback())
        return
    end
    local same = mt._message_type == mtf._message_type
    if not same then
        error("pb_methods:MergeFrom failed! _message_type error", mt._message_type, mtf._message_type)
        return
    end
    self:Clear()
    --print("pb_methods:MergeFrom 1--", self, from, obj)
    makepb.Copy(self, from)
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
    return string.format("%s %s", mt._message_type, makepb.TableToString(self.obj or self))
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