package main

import (
	"github.com/yuin/gopher-lua"
	"os"
	_"fmt"
)

func main(){
	// 启动lua虚拟机
	L := lua.NewState()
	defer L.Close()
	if err := L.DoFile("lua/main.lua"); err != nil {
		panic(err)
	}
	var args []string = os.Args;
	var arg_str string;
	for i:= 1; i < len(args); i++ {
		//fmt.Println("    --" + args[i]);
		if i != (len(args) -1) {
			arg_str = arg_str+ args[i] + " " ;
		}else{
			arg_str = arg_str+ args[i];
		}
	}
	err := L.CallByParam(lua.P{
		Fn:	L.GetGlobal("Start_Cli_Lua"),
		NRet:0,
		Protect: true,
	},lua.LString(arg_str));
	if err != nil {
		panic(err)
	}
	//fmt.Println("arg:" + lua_start_Str);
	
}