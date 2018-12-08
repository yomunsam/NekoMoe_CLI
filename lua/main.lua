require("lua.ext.string")
require("lua.ext.logger")


local NEKO_VERSION = "1.0.0"

--被CLI识别的命令
local m_command = {
    { name = "compress" , short_name = "comp" , func = function(a) cmd_compress(a) end},
    { name = "help" , short_name = "h" , func = function() cmd_help() end},
}

local function LogHelp()
    local title = "NekoMoe 脚手架工具 - ver " .. NEKO_VERSION
    local str = [[

        new             新建工程        参数：app名
        compress        压缩Lua文件     参数：待压缩文件 | 输出文件路径
    ]]
    print(title .. "\n" .. str)
end

local function HandleCommand(head,content)
    --print("head:" .. head)
    for i , v in ipairs(m_command) do 
        if v.name == head or v.short_name == head then 
            if v.func ~= nil then
                v.func(content)
            end
        end
    end
end




--到这里，CLI本体算是启动了
function Start_Cli_Lua(args)
    --dump(args)
    local arg_arr = string.split(args," ")
    --dump(arg_arr)
    if #arg_arr == 0 then
        cmd_help()
    end
    local content = {}
    for i , v in ipairs(arg_arr) do
        if i > 1 then 
            table.insert( content,v)
        end
    end
    HandleCommand(arg_arr[1], content)
end


--------------------------------

function cmd_compress(content)
    local function err(str)
        print(str)
        cmd_help()
    end
    if content == nil then
        err("压缩命令错误：未传入待压缩文件路径")
        return
    end
    if #content < 1 then
        err("压缩命令错误：未传入待压缩文件路径")
        return
    end
    local file_path = content[1]
    local file_output = ""
    if #content >=2 then 
        file_output = content[2]
    else
        file_output = file_path .. ".comp.lua"
    end
    local file = io.open(file_path)
    if file == nil then
        err("指定的文件路径不存在")
        return
    end
    local file_str = file:read("*a")
    file:close()
    --开始压缩代码

    --tab转成1个空格
    while(string.find(file_str,"\t") ~= nil) do
        file_str = string.gsub(file_str,"\t"," ")
        --print(file_str)
    end
    --删空格
    while(string.find(file_str,"  ") ~= nil) do
        file_str = string.gsub(file_str,"  "," ")
        --print(file_str)
    end
    while(string.find(file_str,"\n ") ~= nil) do
        file_str = string.gsub(file_str,"\n ","\n")
        --print(file_str)
    end
    --逐行处理
    local page_arr = string.split(file_str,"\n")
    local line_status = {   --逐行处理中的状态关系
        inNotes = false,    --循环进入注释
        notes_start_index = nil,    --注释开始行
        notes_end_index = nil, --注释结束行
    }
    local will_del = {}
    local will_change = {}
    for i , v in ipairs(page_arr) do
        if v == "" or v == "%s" or v == string.char(13) then
            --print("删空行")
            will_del[i] = "true"
        else
            --多行注释开头判断
            if string.find(v,'--[[',1,true) ~= nil and line_status.inNotes == false then
                line_status.inNotes = true
                --print("[".. i .."]开始多行注释：" .. v)
                local index = string.find(v,'--[[',1,true)
                will_change[i] = string.sub(v,1,index - 1)

                line_status.notes_start_index = i
                line_status.notes_end_index = 0             
            end
            
            --多行注释结束判断
            if string.find(v,']]',1,true) ~= nil and line_status.inNotes then
                --本行不能直接删除
                local index = string.find(v,']]',1,true)
                --print("[".. i .."]结束多行注释：" .. v)
                will_change[i] = string.sub(v,index + 2, string.len( v ))
                line_status.inNotes = false
                line_status.notes_end_index = i
                line_status.notes_start_index = 0
            end

            --多行注释中
            if line_status.inNotes == true and line_status.notes_start_index ~=  i and line_status.notes_end_index ~= i then
                will_del[i] = "true"
                --print("[".. i .."]多行注释中：" .. v)
            end
            
            if line_status.inNotes == false then
                --单行注释处理
                local n_index = string.find(v,'--',1,true)
                if n_index ~= nil then
                    --检查这个--是否是字符串
                    local is_str = false
                    local str_start = string.find(v,string.char( 34 ))
                    if str_start ~= nil then
                        local str_end = string.find(v,string.char( 34 ),str_start + 1)
                        if str_end ~= nil then
                            if str_start < n_index and  str_end > n_index then
                                is_str = true
                            end
                        end
                    end
                    local new_v = v
                    if will_change[i] ~= nil then
                        new_v = will_change[i]
                    end
                    local new_v = string.sub(new_v,1,n_index - 1)
                    if is_str == false then
                        will_change[i] = new_v
                        -- print("发现注释:" .. v)
                        -- print("      " .. new_v)
                    end
                    
                end


            end

        end

    end

    --table还原成文件
    file_str = ""
    for i , v in ipairs(page_arr) do
        if will_del[i] == "true" then
            --print("被删除：" .. v)
        else
            local this_v = v
            if will_change[i] ~= nli then
                this_v = will_change[i]
            end
            file_str = file_str .. this_v
        end
    end

    --
    while(string.find(file_str,string.char(13)) ~= nil) do
        file_str = string.gsub(file_str,string.char(13)," ")
    end

    --写出
    print("out:" .. file_output)
    local f = assert(io.open(file_output,'w'))
    f:write(file_str)
    f:close()
    print("success")
end

function cmd_help()
    LogHelp()
end