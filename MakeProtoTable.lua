-----------------------------
--@brief：创建protobuf对象table
--@date：2025-5-29
--@author：
-----------------------------

--[[
注意：repeated不能序列化，要arr[1]才可以
测试用例：

function test_step_call()
    --RunAllPBTests()
    --p_test8()
    --p_test9()
    --p_test10()
    --p_test11()
    --p_test3()
    --p_test0()
    --p_test1()
    --p_test2()
    --p_test_parse_then_add()
    --p_test_nested_parse_then_add()
    --yali_ceshi()
end

--------------------------------------------------------------------------------
-- ParseFromString·后对 repeated 字段调用 :add() 的测试
-- 复现场景: TDBAllianceRewardAlloc -> list[1].records[1].allocMembers:add()
-- 问题: lpb.decode 后的 repeated 字段没有设置 MakeRepeatedMeta-元表, 导致 :add() 为 nil
--------------------------------------------------------------------------------
function p_test_parse_then_add()
    print(">>> Testing ParseFromString then :add() on repeated field...")
    
    -- 1. 构造带数据的消息并序列化
    local cacheData = MakeProto("CSMsg.TDBAcronPubPerson")
    cacheData.curTaskSID = 100
    
    local task1 = cacheData.tasks:add()
    task1.taskSID = 1
    task1.taskID = 2
    
    local record1 = cacheData.records:add()
    record1.dbid = 12345
    record1.name = "test"
    
    local bytes = cacheData:SerializeToString()
    print("[INFO] Serialized bytes length:", #bytes)
    
    -- 2. 反序列化到新对象
    local loadedData = MakeProto("CSMsg.TDBAcronPubPerson")
    loadedData:ParseFromString(bytes)
    
    -- 3. 验证已有数据
    assert(loadedData.tasks[1] ~= nil,"tasks[1] should exist")
    assert(loadedData.tasks[1].taskSID == 1,"tasks[1].taskSID should be 1")
    assert(loadedData.records[1] ~= nil,"records[1] should exist")
    assert(loadedData.records[1].dbid == 12345,"records[1].dbid should be 12345")
    print("[PASS] Existing data verified")

    -- 4. 关键测试: 在已有数据的 repeated 字段上调用 :add()
    local ok, err = pcall(function()
        local newTask = loadedData.tasks:add() --这里之前会报 "attempt to call a nil value (method 'add')"
        newTask.taskSID = 2
        newTask.taskID = 3
    end)

    if not ok then
        error(string.format("[FAILED] tasks:add() after ParseFromString failed: %s", tostring(err)))
    end
    print("[PASS] tasks:add() after ParseFromString works")

    -- 5. 验证新增的数据
    assert(#loadedData.tasks == 2,"tasks should have 2 elements")
    assert(loadedData.tasks[2].taskSID == 2,"tasks[2].taskSID should be 2")
    print("[PASS] New task data verified")

    -- 6. 验证序列化往返
    local bytes2 = loadedData:SerializeToString()
    local loadedData2 = MakeProto("CSMsg.TDBAcronPubPerson")
    loadedData2:ParseFromString(bytes2)

    assert(#loadedData2.tasks == 2, "Round-trip: tasks should have 2 elements")
    assert(loadedData2.tasks[1].taskSID == 1, "Round-trip: tasks[1].taskSID should be 1")
    assert(loadedData2.tasks[2].taskSID == 2, "Round-trip: tasks[2].taskSID should be 2")
    print("[PASS] Round-trip serialization verified")

    -- 7. 测试空 repeated 字段 (ParseFromString 后该字段为空, 首次访问触发 __index)
    local emptyMsg = MakeProto("CSMsg.TDBAcronPubPerson")
    emptyMsg.curTaskSID = 200
    local emptyBytes = emptyMsg:SerializeToString()

    local loadedEmpty = MakeProto("CSMsg.TDBAcronPubPerson")
    loadedEmpty:ParseFromString(emptyBytes)

    local ok2, err2 = pcall(function()
        local t = loadedEmpty.tasks:add()
        t.taskSID = 99
    end)

    if not ok2 then
        error(string.format("[FAILED] tasks:add() on empty repeated field failed: %s", tostring(err2)))
    end
    assert(#loadedEmpty.tasks == 1, "Empty repeated: tasks should have 1 element")
    assert(loadedEmpty.tasks[1].taskSID == 99, "Empty repeated: tasks[1].taskSID should be 99")
    print("[PASS] Empty repeated field :add() works")

    print("[PASSED] ParseFromString then :add() on repeated field")
end

--------------------------------------------------------------------------------
-- 深层嵌套 repeated 字段的 ParseFromString 后 :add() 测试
-- 复现场景: TDBAllianceRewardAlloc -> list[1].records[1].allocMembers:add()
-- 这是 AllianceRewardAllocData.lua:97 处的实际 bug 场景
--------------------------------------------------------------------------------
function p_test_nested_parse_then_add()
    print(">>> Testing nested ParseFromString then :add()...")

    -- 1. 构造三层嵌套结构的数据
    -- TbsTroopContext -> arrFaction (repeated TFactionAdditionInfo)
    -- 我们用 TDBAcronPubPerson -> tasks (repeated) -> 但 tasks 内部没有 repeated
    -- 用 p_test2 中的结构: TDBAcronPubPerson.tasks[1].pos (嵌套 message)

    -- 使用更复杂的结构来测试
    local msg = MakeProto("CSMsg.TbsTroopContext")
    msg.MasterID = 100

    local fa1 = msg.arrFaction:add()
    fa1.faction = 1
    fa1.factionStage = 10

    local fa2 = msg.arrFaction:add()
    fa2.faction = 2
    fa2.factionStage = 20

    local bytes = msg:SerializeToString()
    print("[INFO] Serialized bytes length:", #bytes)
    
    -- 2. 反序列化
    local loaded = MakeProto("CSMsg.TbsTroopContext")
    loaded:ParseFromString(bytes)

    -- 3. 验证 repeated 元素访问正常
    assert(#loaded.arrFaction == 2, "arrFaction should have 2 elements")
    assert(loaded.arrFaction[1].faction == 1, "arrFaction[1].faction should be 1")
    assert(loaded.arrFaction[2].faction == 2, "arrFaction[2].faction should be 2")
    print("[PASS] Existing data verified")

    -- 4. 在已有数据的 repeated 上 add
    local ok, err = pcall(function()
        local fa3 = loaded.arrFaction:add()
        fa3.faction = 3
        fa3.factionStage = 30
    end)

    if not ok then
        error(string.format("[FAILED] arrFaction:add() after ParseFromString failed: %s", tostring(err)))
    end
    print("[PASS] arrFaction:add() after ParseFromString works")

    -- 5. 验证 ipairs 遍历
    local count = 0
    for i, v in ipairs(loaded.arrFaction) do
        count = count + 1
        assert(getmetatable(v) ~= nil, "ipairs element should have metatable")
    end
    assert(count == 3, "ipairs should iterate 3 elements")
    print("[PASS] ipairs iteration works")

    -- 6. 序列化往返验证
    local bytes2 = loaded:SerializeToString()
    local loaded2 = MakeProto("CSMsg.TbsTroopContext")
    loaded2:ParseFromString(bytes2)

    assert(#loaded2.arrFaction == 3, "Round-trip: arrFaction should have 3 elements")
    assert(loaded2.arrFaction[3].faction == 3, "Round-trip: arrFaction[3].faction should be 3")
    print("[PASS] Round-trip verified")

    -- 7. 再次在 loaded2 上 add (验证多轮 ParseFromString 后仍然正常)
    local ok2, err2 = pcall(function()
        local fa4 = loaded2.arrFaction:add()
        fa4.faction = 4
    end)
    if not ok2 then
        error(string.format("[FAILED] Second round arrFaction:add() failed: %s", tostring(err2)))
    end
    assert(#loaded2.arrFaction == 4, "Second round: arrFaction should have 4 elements")
    print("[PASS] Multiple ParseFromString rounds work")

    print("[PASSED] Nested ParseFromString then :add()")
end

function p_test8()
    local msg = MakeProto1("CSMsg.TbsTroopContext")
    print("msg.weapon=", msg, msg.weapon.weaponId)
    msg.weapon.weaponId = 101
    local sub2 = msg.arrFaction:add()
    sub2.faction = 11
    sub2.factionStage = 22
    sub2.factionProLv = 33
    local sub44 = MakeProto1("CSMsg.TFactionAdditionInfo")
    sub44.faction = 1111
    sub44.factionStage = 2222
    sub44.factionProLv = 3333
    local strfa = sub44:SerializeToString()
    local sub3 = msg.arrFaction:add()
    sub3:ParseFromString(strfa)

    local sub55 = MakeProto1("CSMsg.TFactionAdditionInfo")
    sub55.faction = 11111
    sub55.factionStage = 22222
    sub55.factionProLv = 33333
    table.insert(msg.arrFaction, sub55)

    -- warning("p8 1--", getmetatable(msg)._data.arrFaction, getmetatable(msg.arrFaction)._data)
    --warning("p8 2--", getmetatable(msg.arrFaction[1])._data, getmetatable(msg.arrFaction[2])._data)

    --warning("p_test8 1-----------", tableView(getmetatable(msg)._data), tableView(getmetatable(msg.arrFaction)._data))

    local str = msg:SerializeToString()
    local newmsg = MakeProto1("CSMsg.TbsTroopContext")
    newmsg:ParseFromString(str)
    warning("p_test8 2-----------", newmsg:ToString())
end

function p_test9()
    local msg = MakeProto1("CSMsg.tEquipInfo")
    print("p_test9 msg=", getmetatable(msg), msg.proId)
    msg.equipid = 1
    msg.lv = 2
    msg.proId[1] = 101
    table.insert(msg.proId, 102)
    msg.resonanceproId = 1
    msg.secondArtifactLevel = 12
    msg.isExclusive = 0
    warning("p_test9-----------", msg:ToString())
    local newmsg = MakeProto1("CSMsg.tEquipInfo")
    newmsg:ParseFromString(msg:SerializeToString())
    warning("p_test9 newmsg=", newmsg:ToString())
end

function p_test10()
    local msg = MakeProto1("CSMsg.TbsTroopContext")
    print("msg.weapon=", msg, getmetatable(msg), msg.weapon)
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
    sub33.faction = 111
    sub33.factionStage = 222
    sub33.factionProLv = 333
    sub3:MergeFrom(sub33)

    local sub4 = msg.arrFaction:add()
    local sub44 = MakeProto1("CSMsg.TFactionAdditionInfo")
    sub44.faction = 1111
    sub44.factionStage = 2222
    sub44.factionProLv = 3333
    sub4:ParseFromString(sub44:SerializeToString())

    local sub5 = msg.arrFaction:add()
    local sub55 = MakeProto1("CSMsg.TFactionAdditionInfo")
    sub55.faction = 11111
    sub55.factionStage = 22222
    sub55.factionProLv = 33333
    local newsub55 = MakeProto1("CSMsg.TFactionAdditionInfo")
    newsub55:ParseFromString(sub55:SerializeToString())
    sub5:MergeFrom(newsub55)
    warning("p_test10 before SerializeToString")
    local str = msg:SerializeToString()
    local newmsg = MakeProto1("CSMsg.TbsTroopContext")
    newmsg:ParseFromString(str)
    warning("p_test10-----------", newmsg:ToString())
end

function p_test11()
    local msg = MakeProto1("CSMsg.TbsTroopContext")
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
    sub33.faction = 111
    sub33.factionStage = 222
    sub33.factionProLv = 333
    sub3:MergeFrom(sub33)
    local str = msg:SerializeToString()
    local newmsg = MakeProto1("CSMsg.TbsTroopContext")
    warning("before ParseFromString-----------", newmsg)
    newmsg:ParseFromString(str)
    warning("after ParseFromString------------", newmsg, getmetatable(newmsg), getmetatable(newmsg.arrFaction))
    
    local sub4 = MakeProto1("CSMsg.TFactionAdditionInfo")
    sub4.faction = 1111
    sub4.factionStage = 2222
    sub4.factionProLv = 3333
    local fastr4 = sub4:SerializeToString()

    --warning("p_test11 newmsg.weapon========", newmsg.weapon:ToString())
    local wpmsg = MakeProto1("CSMsg.TbsWeaponContext")
    wpmsg.weaponId = 101
    local wp1 = wpmsg.part:add()
    wp1.partType = 1
    wp1.nLv = 10
    wpmsg.mateLv = 10
    local wpstr = wpmsg:SerializeToString()
    newmsg.weapon:ParseFromString(wpstr)
    --print("p_test11 newmsg.weapon after parse========", newmsg.weapon:ToString())

    --warning("p_test11 newmsg.arrFaction=====", newmsg.arrFaction:ToString())
    warning("p_test11 newmsg.arrFaction[2]=", newmsg.arrFaction[2])
    newmsg.arrFaction[2]:ParseFromString(fastr4)
    local t55 = {}
    for i, v in ipairs(newmsg.arrFaction) do
        print("arrFaction 55 mt--", i, getmetatable(v))
        t55[i] = MakeProto1("CSMsg.TFactionAdditionInfo")
        t55[i]:MergeFrom(v)
        print("p_test11 t55[i]=", i, t55[i]:ToString())
    end
    local str1 = newmsg:SerializeToString()
    print("p_test11 str1 size=", #str1)

    local newmsg11 = MakeProto1("CSMsg.TbsTroopContext")
    newmsg11:ParseFromString(str1)
    warning("p_test11 newmsg11=", newmsg11:ToString())
end

function p_test3()
    local msg = MakeProto1("CSMsg.TbsTroopContext")
    msg.weapon.weaponId = 101
    local sub1 = msg.arrFaction:add()
    sub1.faction = 1
    sub1.factionStage = 2
    sub1.factionProLv = 3

    local famsg = MakeProto1("CSMsg.TFactionAdditionInfo")
    famsg.faction = 11
    famsg.factionStage = 22
    famsg.factionProLv = 33
    local fastr = famsg:SerializeToString()
    local sub2 = msg.arrFaction:add()
    sub2:ParseFromString(fastr)
    local str = msg:SerializeToString()
    print("str size=", #str, msg:ToString())
end

function p_test0()
    local msg = MakeProto1("CSMsg.TbsTroopContext")
    print("k1--", msg.MasterID, msg.dir, msg.haloids)
    msg.weapon.weaponId = 101
    local sub1 = msg.arrFaction:add()
    sub1.faction = 1
    sub1.factionStage = 2
    sub1.factionProLv = 3
    local str = msg:SerializeToString()
    local newmsg = MakeProto1("CSMsg.TbsTroopContext")
    newmsg:ParseFromString(str)
    print("newmsg1=", newmsg.arrFaction, newmsg.arrFaction:ToString())
    newmsg.arrFaction:Clear()
    print("newmsg2=", newmsg.arrFaction:ToString())
    print("newmsg3=", newmsg:ToString())
end

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
    local dbid  = 134292
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


-- 辅助：简单的断言函数
local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("[FAILED] %s | Expected: %s, Actual: %s", msg, tostring(expected), tostring(actual)))
    end
end

--------------------------------------------------------------------------------
-- 1. 基础读写与默认值测试 (Proto2 特性)
--------------------------------------------------------------------------------
local function TestBasics()
    print(">>> Testing Basics & Defaults...")
    local report = MakeProto1("CSMsg.NumericReport")
    
    -- 验证枚举默认值 (NumericType_HP = 1)
    assert_eq(report.numType, 1, "Enum default value")
    -- 验证 int64 默认值
    assert_eq(report.numbers, 0, "Int64 default value")
    -- 验证 bool 默认值 (Proto2 optional bool 默认为 false)
    assert_eq(report.Critical, false, "Bool default value")
    
    -- 赋值与读取
    report.numbers = 1234567890123
    assert_eq(report.numbers, 1234567890123, "Int64 assignment")
    
    print("[PASSED] Basics & Defaults")
end

--------------------------------------------------------------------------------
-- 2. 深度嵌套与链路回溯同步测试 (核心功能)
--------------------------------------------------------------------------------
local function TestDeepSync()
    print(">>> Testing Deep Chain Sync...")
    
    -- 结构: TbsReports -> TbsReport -> BuildReport -> PalReportContext (Animal)
    local reports = MakeProto1("CSMsg.TbsReports")
    local r1 = reports.reports:add()
    r1.reportType = 1 -- ReportType_BuildReport
    
    -- 访问深层 optional 结构并赋值
    r1.buildReport.leftAnimal.cfgID = 1001
    r1.buildReport.leftAnimal.palID = 50
    
    -- 构造一份独立的 BuildReport 协议数据
    local sub_build = MakeProto1("CSMsg.BuildReport")
    sub_build.mapID = 777
    sub_build.leftID = 888
    local bin = sub_build:SerializeToString()
    
    -- 在嵌套深度为 2 的地方执行 Parse
    print("Performing sub-message Parse...")
    r1.buildReport:ParseFromString(bin)
    
    -- 验证 1: 当前代理是否更新
    assert_eq(r1.buildReport.mapID, 777, "Sub-proxy mapID")
    
    -- 验证 2: 根节点序列化后，是否包含刚才 Parse 的数据 (回溯同步)
    local root_bin = reports:SerializeToString()
    local root_data = makepb._lpb.decode("CSMsg.TbsReports", root_bin)
    
    assert_eq(root_data.reports[1].buildReport.mapID, 777, "Root sync after sub-parse")
    assert_eq(root_data.reports[1].buildReport.leftID, 888, "Root sync after sub-parse 2")

    print("[PASSED] Deep Chain Sync")
end

--------------------------------------------------------------------------------
-- 3. 数组 (Repeated) 操作测试
--------------------------------------------------------------------------------
local function TestRepeated()
    print(">>> Testing Repeated Fields (Scalars & Messages)...")
    local build = MakeProto1("CSMsg.BuildReport")
    
    -- A. 标量数组 (int32)
    table.insert(build.leftHaloids, 101)
    table.insert(build.leftHaloids, 102)
    assert_eq(#build.leftHaloids, 2, "Scalar array length")
    assert_eq(build.leftHaloids[1], 101, "Scalar array index 1")
    
    -- B. 消息数组 (add 方法)
    local pal = build.leftPals:add()
    pal.palID = 1
    pal.cfgID = 5001
    
    assert_eq(#build.leftPals, 1, "Message array length")
    assert_eq(build.leftPals[1].palID, 1, "Message array proxy access")
    
    -- C. ipairs 遍历 (验证代理包装)
    for i, v in ipairs(build.leftPals) do
        assert_eq(v.cfgID, 5001, "ipairs proxy access")
        -- 验证 v 是否有元方法
        assert(getmetatable(v) ~= nil, "ipairs element should be a proxy")
    end
    
    -- D. 数组元素 Parse 回溯
    local p2_raw = { palID = 2, cfgID = 6006 }
    local p2_bin = makepb._lpb.encode("CSMsg.PalReportContext", p2_raw)
    
    local pal2 = build.leftPals:add()
    pal2:ParseFromString(p2_bin)
    
    assert_eq(build.leftPals[2].cfgID, 6006, "Repeated element parse sync")
    
    print("[PASSED] Repeated Fields")
end

--------------------------------------------------------------------------------
-- 4. 跨消息赋值 (自动脱壳) 测试
-- 注意：此测试仅在代理模式 (IsProxyModel() == true) 下有意义
--------------------------------------------------------------------------------
local function TestCrossAssignment()
    print(">>> Testing Cross-Message Assignment (Unwrapping)...")
    
    -- 非代理模式下跳过此测试
    if not makepb.IsProxyModel() then
        print("[SKIPPED] Cross-Message Assignment (only for proxy mode)")
        return
    end
    
    local troop1 = MakeProto1("CSMsg.TbsTroopContext")
    local troop2 = MakeProto1("CSMsg.TbsTroopContext")
    
    troop2.weapon.weaponId = 555
    troop2.weapon.mateLv = 10
    
    -- 将 troop2 的子代理赋值给 troop1
    print("Assigning proxy to another message...")
    troop1.weapon = troop2.weapon
    
    -- 验证 1: 读取正常
    assert_eq(troop1.weapon.weaponId, 555, "Assigned proxy read")
    
    -- 验证 2: 物理结构是否正确 (troop1._data.weapon 应该是 table 而不是 proxy)
    local raw_data = getmetatable(troop1)._data
    assert(getmetatable(raw_data.weapon) == nil, "Data should be unwrapped (no metatable)")
    
    -- 验证 3: 序列化正常
    local bin = troop1:SerializeToString()
    local check = makepb._lpb.decode("CSMsg.TbsTroopContext", bin)
    assert_eq(check.weapon.weaponId, 555, "Assigned proxy serialization")
    
    print("[PASSED] Cross-Message Assignment")
end

--------------------------------------------------------------------------------
-- 5. MergeFrom 与 Clear 测试
--------------------------------------------------------------------------------
local function TestMergeAndClear()
    print(">>> Testing MergeFrom & Clear...")
    
    local msg1 = MakeProto1("CSMsg.TSoldierNum")
    msg1.lv = 10
    msg1.num = 500
    
    local msg2 = MakeProto1("CSMsg.TSoldierNum")
    msg2:MergeFrom(msg1)
    
    assert_eq(msg2.lv, 10, "MergeFrom value 1")
    assert_eq(msg2.num, 500, "MergeFrom value 2")
    
    msg2:Clear()
    assert_eq(msg2.lv, 0, "Clear value (returns to default)")
    
    -- 复杂结构 Merge
    local t1 = MakeProto1("CSMsg.TbsTroopContext")
    t1.weapon.weaponId = 1
    t1.arrFaction:add().faction = 2
    
    local t2 = MakeProto1("CSMsg.TbsTroopContext")
    t2:MergeFrom(t1)
    assert_eq(t2.weapon.weaponId, 1, "Nested Merge 1")
    assert_eq(t2.arrFaction[1].faction, 2, "Nested Merge 2")
    
    print("[PASSED] MergeFrom & Clear")
end

--------------------------------------------------------------------------------
-- 6. 极端情况：Int64 精度与打印测试
--------------------------------------------------------------------------------
local function TestExtreme()
    print(">>> Testing Extreme Cases (Int64 & Printing)...")
    
    local msg = MakeProto1("CSMsg.NumericReport")
    -- 测试一个大的 Int64 (超过 2^53-1 可能在某些 Lua 环境丢失精度，取决于 lpb 实现)
    local bigNum = 9007199254740993 
    msg.numbers = bigNum
    
    local str = msg:ToString()
    -- print(str) -- 验证 TableToString 不卡顿
    assert(string.find(str, "numbers = 9007199254740993"), "ToString Int64 check")
    
    print("[PASSED] Extreme Cases")
end

--------------------------------------------------------------------------------
-- 执行全部测试
--------------------------------------------------------------------------------
function RunAllPBTests()
    local ok, err = pcall(function()
        TestBasics()
        TestDeepSync()
        TestRepeated()
        TestCrossAssignment()
        TestMergeAndClear()
        TestExtreme()
    end)
    
    if ok then
        print("\n" .. string.rep("=", 30))
        print("  ALL PB TESTS PASSED!  ")
        print(string.rep("=", 30))
    else
        print("\n" .. string.rep("!", 30))
        print("  TESTS FAILED: " .. tostring(err))
        print(string.rep("!", 30))
    end
end

test_step_call()
]]--

---------------------------------------- makepb -------------------------------------------
local makepb = {
    _lpb = nil,
    type_default_val = nil,
    fieldTypes = {},
    pb_methods = {},
    pb_methods_new = {},
    proxy_mt_cache = {},
}

local pb_methods = makepb.pb_methods

makepb.type_default_val = {
    ["int32"] = 0, ["uint32"] = 0, ["fixed32"] = 0, ["sfixed32"] = 0, ["sint32"] = 0,
    ["int64"] = 0, ["uint64"] = 0, ["fixed64"] = 0, ["sfixed64"] = 0, ["sint64"] = 0,
    ["double"] = 0, ["float"] = 0, ["string"] = "", ["bytes"] = "", ["bool"] = false,
}

function lpbEnumVal(message_type, fieldName)
    return makepb._lpb.enum(message_type, fieldName)
end

function lpbEncode(message_type, t)
    return makepb._lpb.encode(message_type, t)
end

function lpbDecode(message_type, data)
    return makepb._lpb.decode(message_type, data)
end

function MakeProto(message_type)
    return makepb.New(message_type)()
end

--是否是使用代理模式
function makepb.IsProxyModel()
    local Utils = require "Utils"
    if Utils.IsZoneServer() then
        local worldId = CPP_GetGameWorldID()
        -- 先只对外10001-10008服
        if worldId <= 10008 then
            return true
        end
    end
    return false
end

function makepb.New(message_type)
    if makepb.IsProxyModel() then
        local function ctor()
            return makepb.CreateProxy({}, message_type, nil, nil)
        end
        return ctor
    end
    local function ctor()
        local obj = makepb.SetLazyDefaults({}, message_type)
        return obj
    end
    return ctor
end

---------------------------------------- makepb new start -------------------------------------------

-- 创建代理对象
function makepb.CreateProxy(raw_data, message_type, parent_raw, key_in_parent)
    if message_type == nil or type(raw_data) ~= "table" then
        error("CreateProxy message_type nil", type(raw_data), debug.traceback())
        return raw_data
    end
    message_type = makepb.AmendName(message_type)
    local mt = makepb.proxy_mt_cache[message_type]
    mt = mt or {
        _index = function(t, k)
            -- 1、优先方法
            --print("CreateProxy 1--", message_type, k)
            if makepb.pb_methods_new[k] then
                return makepb.pb_methods_new[k]
            end

            local cur_mt = getmetatable(t)
            local raw = cur_mt._data
            local val = raw[k]

            -- 访问数组索引，k是number，field_types[k] == nil
            -- 所以放 local info = field_types and field_types[k]
            if type(k) == "number" then
                if type(val) == "table" and not getmetatable(val) then
                    -- 如果是 table 且没设元表，说明是待包装的消息
                    --print("CreateProxy 4--", message_type, k, val)
                    return makepb.CreateProxy(val, message_type, raw, k)
                end
                return val
            end

            local field_types = makepb.GetFieldTypes(message_type)
            local info = field_types and field_types[k]
            if not info then
                --error("CreateProxy field_type nil", message_type, k, debug.traceback())
                return nil
            end

            local pb = makepb._lpb
            local name2, _, type2 = pb.type(info.type1)
            --print("CreateProxy 3--", message_type, k, val, name2, type2, info.type1, info.label)

            -- message 消息或数组，实现延迟包装
            if info.label == "repeated" or type2 == "message" then
                -- 如果不存在，则创建一个空数组，并包装它
                if val == nil then
                    val = {}
                    raw[k] = val
                end
                --print("CreateProxy 5--", message_type, k, val, name2, type2, info.label)
                return makepb.CreateProxy(val, name2 or info.type1, raw, k)
            end

            -- 如果是普通字段且为 nil，返回默认值
            if val == nil then
                if type2 == "enum" then
                    return makepb.GetEnumDefaultVal(pb, name2)
                end
                return makepb.type_default_val[info.type1]
            end
            
            return val
        end,

        _newindex = function(t, k, v)
            -- local cur_mt = getmetatable(t)
            -- print("CreateProxy __newindex--", message_type, k, v, t, cur_mt, cur_mt._data)
            -- cur_mt._data[k] = v
            local mt = getmetatable(t)
            -- 如果赋值的是代理对象，只存原始数据
            local v_mt = getmetatable(v)
            if v_mt and v_mt._data then
                mt._data[k] = v_mt._data
            else
                mt._data[k] = v
            end
        end,

        _pairs = function(t)
            local raw = getmetatable(t)._data
            return function(_, k)
                local nk = next(raw, k)
                if nk == nil then
                    return nil
                end
                return nk, t[nk]   -- 调用__index创建代理
            end, t, nil
        end,
        
        -- ipairs 迭代器
        _ipairs = function(t)
            local iter = function(proxy, i)
                i = i + 1
                local v = proxy[i] -- 必须走 proxy[i] 以触发延迟包装
                if v ~= nil then
                    return i, v
                end
            end
            return iter, t, 0
        end,

        -- #msg.data
        _len = function(t)
            local cur_mt = getmetatable(t)
            return #cur_mt._data
        end,
    }

    --缓存元表
    if not makepb.proxy_mt_cache[message_type] then
        makepb.proxy_mt_cache[message_type] = mt
    end

    local instance_mt = {
        _message_type = message_type,
        _data = raw_data,
        _parent_raw = parent_raw,        -- 记录父级 raw 表
        _key_in_parent = key_in_parent,  -- 记录自己在父级里的 key
        __index = mt._index,
        __newindex = mt._newindex,
        __pairs = mt._pairs,
        __ipairs = mt._ipairs,
        __len = mt._len,
    }

    local proxy = {}
    return setmetatable(proxy, instance_mt)
end

---------------------------------------- pb_methods new -------------------------------------------
function makepb.pb_methods_new:ParseFromString(data)
    local mt = getmetatable(self)
    if mt == nil then
        error("ParseFromString mt nil", debug.traceback())
        return
    end

    -- 清空数据
    self:Clear()

    -- 直接 decode 出一个原始 table，不带任何元表
    --local raw = makepb._lpb.decode(type_name, data)
    local raw = makepb._lpb.decode(mt._message_type, data, mt._data)
    if not raw then
        error("decode failed", mt._message_type, debug.traceback())
    end
    
    -- 核心优化：直接替换数据源，没有任何递归，时间复杂度 O(1)
    --instance_mt._data = raw

    -- 3. 【链式反应的关键】：同步给直接父级
    -- 更新直接父级，则更高的节点可通过原有的引用链看到这里
    if mt._parent_raw and mt._key_in_parent then
        mt._parent_raw[mt._key_in_parent] = mt._data
    end
end

function makepb.pb_methods_new:SerializeToString()
    local mt = getmetatable(self)
    return makepb._lpb.encode(mt._message_type, mt._data)
end

function makepb.pb_methods_new:add()
    local instance_mt = getmetatable(self)
    local raw_list = instance_mt._data
    local element_type = instance_mt._message_type -- 这里的类型是数组元素的类型
    --print("pb_methods:add --", element_type, instance_mt, raw_list)
    -- 1. 创建一个新的原始 Table 存放数据
    local new_element_raw = {}
    
    -- 2. 插入到原始数组中，建立物理链接
    raw_list[#raw_list+1] = new_element_raw
    
    -- 3. 返回这个新元素的代理壳
    -- 注意：这里传入了父表(raw_list)和索引(#raw_list)以保持引用链路
    return makepb.CreateProxy(new_element_raw, element_type, raw_list, #raw_list)
end

-- 追加元素到string/number的repeated 数组
function makepb.pb_methods_new:append(item)
    if type(item) ~= "string" and type(item) ~= "number" then
        error("append item val type error. type=", type(item))
        return
    end
    local mt = getmetatable(self)
    local raw = mt._data
    raw[#raw + 1] = item
end

-- 移除指定位置元素，语义与 table.remove 一致
function makepb.pb_methods_new:remove(i)
    local mt = getmetatable(self)
    return table.remove(mt._data, i)
end

function makepb.pb_methods_new:MergeFrom(from)
    local mt_self = getmetatable(self)
    -- 兼容处理：如果 'from' 是代理对象，取其 _data；如果是普通 table，直接使用
    local mt_from = getmetatable(from)
    local from_raw = mt_from and mt_from._data or from
    local from_type = mt_from and mt_from._message_type or nil

    -- 类型检查
    if from_type and mt_self._message_type ~= from_type then
        error(string.format("MergeFrom failed! type mismatch: %s vs %s", mt_self._message_type, from_type))
        return
    end

    -- 1. 清空当前数据
    self:Clear()

    -- 2. 将数据从 from_raw 深拷贝到自己的 _data 中
    -- 注意：makepb.Copy 必须是作用于原始 table 的
    makepb.Copy(mt_self._data, from_raw)
    
    -- 注意：由于我们是深拷贝了数据到原本的 _data 地址中，
    -- 所有父节点对当前 _data 的引用依然有效，不需要更新父节点。
end

function makepb.pb_methods_new:Clear()
    local instance_mt = getmetatable(self)
    local raw = instance_mt._data
    if raw then
        for k, v in pairs(raw) do
            raw[k] = nil
        end
    end
end

function makepb.pb_methods_new:ToString()
    local mt = getmetatable(self)
    return string.format("%s %s", mt._message_type, makepb.TableToString(mt._data))
end

function makepb.pb_methods_new:HasField(fieldName)
    local mt = getmetatable(self)
    if mt == nil or mt._data == nil then
        return false
    end
    return mt._data[fieldName] ~= nil
end

-- 脱壳 + 深拷贝：代理对象取 _data 后拷贝，普通 table 也拷贝一份，
-- 避免同一对象多次插入数组时共享引用
function makepb._UnwrapForInsert(v)
    local vmt = getmetatable(v)
    if vmt and vmt._data then
        return makepb.Copy({}, vmt._data)
    end
    if type(v) == "table" then
        return makepb.Copy({}, v)
    end
    return v
end

---------------------------------------- makepb new end -------------------------------------------

function makepb.SetLazyDefaults(obj, message_type)
    if message_type == nil then
        error("makepb.SetLazyDefaults message_type nil", debug.traceback())
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

function makepb.MakeRepeatedMeta(repeated_message_type)
    repeated_message_type = makepb.AmendName(repeated_message_type)
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
    local pb = makepb._lpb
    local mt = getmetatable(obj)
    --print("makepb.SetMeta 1--", message_type, mt)
    if mt == nil then
        obj = makepb.SetLazyDefaults(obj, message_type)
    end
    local field_types = makepb.GetFieldTypes(message_type)
    for k, v in pairs(obj) do
        repeat
            local info = field_types[k]
            if info == nil then
                error("makepb.SetMeta info nil", message_type, k, debug.traceback())
                break
            end
            --非message/repeated
            if type(v) ~= "table" then
                break
            end
            local name2, _, type2 = pb.type(info.type1)
            --print("makepb.SetMeta 2--", message_type, k, info.type1, info.label, type2)
            if info.label == "repeated" then
                for i, elem in ipairs(v) do
                    --print("makepb.SetMeta 3--", message_type, k, i, name2)
                    v[i] = makepb.SetMeta(elem, name2)
                end
                -- repeated 数组本身也挂上 metatable, 否则 lpb decode 后的裸数组
                -- 访问 :add()/:Clear() 等方法会拿不到
                if type2 == "message" and not getmetatable(v) then
                    setmetatable(v, makepb.MakeRepeatedMeta(name2))
                end
            else
                --print("makepb.SetMeta 4--", message_type, k, i, name2)
                obj[k] = makepb.SetMeta(v, name2)
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
        error("makepb.AmendName message_type nil", debug.traceback())
        return message_type
    end
    --修正 message_type，因为pb.fields返回的值是.CSMsg.xxx 多个.号
    if string.byte(message_type) == 46 then -- 46 == string.byte(".")
        message_type = string.sub(message_type, 2)
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

function makepb.TableToString(tbl)
    local buffer = {"{\n"}
    local visited = {}
    local function dump(t, depth)
        if type(t) ~= "table" then 
            table.insert(buffer, tostring(t))
            return 
        end
        if visited[t] then table.insert(buffer, '"<cycle>"') return end
        visited[t] = true
        local space = string.rep("  ", depth)
        local nspace = space .. "  "
        for k, v in pairs(t) do
            table.insert(buffer, nspace .. tostring(k) .. " = ")
            if type(v) == "table" then
                table.insert(buffer, "{\n")
                dump(v, depth + 1)
                table.insert(buffer, nspace .. "},\n")
            else
                local fmt = type(v) == "string" and '"%s"' or "%s"
                table.insert(buffer, string.format(fmt .. ",\n", tostring(v)))
            end
        end
        visited[t] = nil
    end
    dump(tbl, 0)
    table.insert(buffer, "}")
    return table.concat(buffer)
end

---------------------------------------- pb_methods -------------------------------------------
function pb_methods:SerializeToString()
    local mt = getmetatable(self)
    return makepb._lpb.encode(mt._message_type, self._obj or self)
end

function pb_methods:ParseFromString(data)
    local mt = getmetatable(self)
    --print("makepb.ParseFromString 0--", mt._message_type, self, mt)
    self:Clear()
    self = makepb._lpb.decode(mt._message_type, data, self)
    self = makepb.SetMeta(self, mt._message_type)
end

function pb_methods:add()
    local mt = getmetatable(self)
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
        error("pb_methods:MergeFrom failed! _message_type error", mt._message_type, mtf._message_type, debug.traceback())
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
    makepb._lpb.option("enum_as_value")
    local ret, val = makepb._lpb.load(data)
    assert(ret, "_lpb_init failed!")
    print("_lpb_init suc.", ret, val, makepb._lpb.type("CSMsg.TbsTroopContext"))
end
_lpb_init()

--[[
1、语义对齐
    和 :add() + :MergeFrom(item) 完全等价：先建空 table，再把数据复制进去。
    用户意图也更符合直觉：把一个消息"加进数组"通常是想要它的值，而不是持有引用。

2、代价
    每次 table.insert 多一次 makepb.Copy 深拷贝(仅针对protobuf结构)
    Copy 已经有 cycle 保护（seen 表），对 pb 这种树形结构是 O(n) where n = 字段数
    对小消息几乎无感知；对巨大消息（如带几百个子字段的 context）确实比纯引用慢
    但这份开销和 :add() + :MergeFrom 已有的开销是一样的，不是新增的成本

3、性能注意事项（修改本函数前请阅读）
    本函数被全局调用，是热路径。务必遵守以下原则，避免引入回归：

    a) 必须用 rawget 读 metatable 字段，不要写成 mt._message_type / mt._data
    原因：mt._key 会触发 __index 元方法链，若 mt 自身也设了 metatable
    会进一步查找，每次 insert 多 N 次哈希查找，且 JIT 不友好。
    rawget(mt, "_key") 是单次 O(1) 哈希查找，无副作用。

    b) getmetatable / rawget 必须缓存为 upvalue（raw_getmetatable / raw_rawget）
    原因：直接写 getmetatable(t) 每次都要走全局表查找；缓存为 upvalue
    后是直接索引，每次省一次哈希。

    c) 普通 table 路径（无 metatable 或非 pb proxy）必须尽早 fallback 到 raw_insert
    原因：99% 的业务调用走这条路径，路径越浅越好。不要把 pb 处理逻辑
    放在前面。

    d) b == nil 时必须用 raw_insert(t, a) 两参形式，不要传 raw_insert(t, a, nil)
    原因：原生 table.insert 看到第三个参数会按"指定位置插入"解析，
    若 a 不是数字会报 "number expected" 错误。
]]

--- 为了兼容旧的写法，重写table.insert
function makepb.ResetTableInsert()
    print("makepb.ResetTableInsert----------")
    local raw_insert = table.insert
    local raw_getmetatable = getmetatable
    local raw_rawget = rawget
    ---@diagnostic disable-next-line: duplicate-set-field, redundant-parameter
    function table.insert(t, a, b)
        local mt = raw_getmetatable(t)
        if mt == nil or raw_rawget(mt, "_message_type") == nil then
            if b == nil then
                return raw_insert(t, a)
            end
            return raw_insert(t, a, b)
        end
        local raw = raw_rawget(mt, "_data")
        if raw == nil then
            if b == nil then
                return raw_insert(t, a)
            end
            return raw_insert(t, a, b)
        end
        if b == nil then
            -- table.insert(proxy, item)
            -- 非拷贝版本
            local vmt = raw_getmetatable(a)
            raw[#raw + 1] = (vmt and vmt._data) or a

            -- 拷贝版本
            -- raw[#raw + 1] = makepb._UnwrapForInsert(a)
        else
            -- table.insert(proxy, pos, item)
            -- 非拷贝版本
            local vmt = raw_getmetatable(b)
            raw_insert(raw, a, (vmt and vmt._data) or b)

            -- 拷贝版本
            -- raw_insert(raw, a, makepb._UnwrapForInsert(b))
        end
    end
end

if makepb.IsProxyModel() then
    makepb.ResetTableInsert()
end

return makepb
