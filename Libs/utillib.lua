local util = {}

function util.tablePrint(t)
    log("INFO | table: "..tostring(t))
    if not t then return end
    for i, v in pairs(t) do
       log("index: "..tostring(i).. "\tvalue: "..tostring(v))
    end
end

--link: https://web.archive.org/web/20131225070434/http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3s
--seemed to be working before, isn't for this project. upper linke is also dead, therefore replaced
function util.deepcompare(t1,t2,ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not util.deepcompare(v1,v2, ignore_mt) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not util.deepcompare(v1,v2, ignore_mt) then return false end
    end
    return true
end



--https://stackoverflow.com/questions/25922437/how-can-i-deep-compare-2-lua-tables-which-may-or-may-not-have-tables-as-keys
function util.table_eq(table1, table2)
    local avoid_loops = {}
    local function recurse(t1, t2)
        -- compare value types
        if type(t1) ~= type(t2) then return false end
        -- Base case: compare simple values
        if type(t1) ~= "table" then return t1 == t2 end
        -- Now, on to tables.
        -- First, let's avoid looping forever.
        if avoid_loops[t1] then return avoid_loops[t1] == t2 end
        avoid_loops[t1] = t2
        -- Copy keys from t2
        local t2keys = {}
        local t2tablekeys = {}
        for k, _ in pairs(t2) do
            if type(k) == "table" then table.insert(t2tablekeys, k) end
            t2keys[k] = true
        end
        -- Let's iterate keys from t1
        for k1, v1 in pairs(t1) do
            local v2 = t2[k1]
            if type(k1) == "table" then
                -- if key is a table, we need to find an equivalent one.
                local ok = false
                for i, tk in ipairs(t2tablekeys) do
                    if util.table_eq(k1, tk) and recurse(v1, t2[tk]) then
                        table.remove(t2tablekeys, i)
                        t2keys[tk] = nil
                        ok = true
                        break
                    end
                end
                if not ok then return false end
            else
                -- t1 has a key which t2 doesn't have, fail.
                if v2 == nil then return false end
                t2keys[k1] = nil
                if not recurse(v1, v2) then return false end
            end
        end
        -- if t2 has a key which t1 doesn't have, fail.
        if next(t2keys) then return false end
        return true
    end
    return recurse(table1, table2)
end


--https://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-values
function util.copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[util.copy(k, s)] = util.copy(v, s) end
    return res
end

return util