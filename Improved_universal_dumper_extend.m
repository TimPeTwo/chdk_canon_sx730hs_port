' dump ROM to A/PRIMARY.BIN 
' log to A/CBDUMPER.LOG
' progress is not displayed on VxWorks cams
' a working script blocks the camera until finished
 
DIM startaddr=0
DIM foundaddr=0
DIM os="unk"
DIM lcdmsg=0
DIM msgstr=0
DIM romsize=0
 
' detect start address and OS
' order must be from highest to lowest, since accessing outside of ROM may trigger an exception
private sub GetStart()
	' get an address that is hopefully in ROM area
	foundaddr=CreateProxyOfEventProcedure("CreateTask")
	DeleteProxyOfEventProcedure("CreateTask")
	if foundaddr > 0xffc00000 then
		if memcmp(0xFFC00004,"gaonisoy",8) = 0 then
			startaddr = 0xFFC00000
			os = "dry"
			exit sub
		end if
		if memcmp(0xFFC00008,"Copyrigh",8) = 0 then
			startaddr = 0xFFC00000
			os = "vx"
			exit sub
		end if
		if memcmp(0xFF810004,"gaonisoy",8) = 0 then
			startaddr = 0xFF810000
			os = "dry"
			exit sub
		end if
		if memcmp(0xFF820004,"gaonisoy",8) = 0 then
			startaddr = 0xFF810000
			os = "dry"
			exit sub
		end if
		if memcmp(0xFF810008,"Copyrigh",8) = 0 then
			startaddr = 0xFF810000
			os = "vx"
			exit sub
		end if
	end if
	if foundaddr > 0xff800000 then
		if memcmp(0xFF810004,"gaonisoy",8) = 0 then
			startaddr = 0xFF810000
			os = "dry"
			exit sub
		end if
		if memcmp(0xFF820004,"gaonisoy",8) = 0 then
			startaddr = 0xFF810000
			os = "dry"
			exit sub
		end if
		if memcmp(0xFF810008,"Copyrigh",8) = 0 then
			startaddr = 0xFF810000
			os = "vx"
			exit sub
		end if
	end if
	if foundaddr > 0xff000000 then
		if memcmp(0xFF000004,"gaonisoy",8) = 0 then
			startaddr = 0xFF000000
			os = "dry"
			exit sub
		end if
		if memcmp(0xFF020004,"gaonisoy",8) = 0 then
			startaddr = 0xFF010000
			os = "dry"
			exit sub
		end if
	end if
	if foundaddr > 0xfc000000 then
		if memcmp(0xFC020004,"gaonisoy",8) = 0 then
			startaddr = 0xFC000000
			os = "dry"
			romsize = 0x2000000
			exit sub
		end if
	end if
	if foundaddr > 0xf8000000 then
		if memcmp(0xFF000004,"gaonisoy",8) = 0 then
			startaddr = 0xFF000000
			os = "dry"
			exit sub
		end if
	end if
	if foundaddr > 0xe0000000 then
		if memcmp(0xE0020004,"gaonisoy",8) = 0 then
			startaddr = 0xE0000000
			os = "dry"
			romsize = 0x2000000
			exit sub
		end if
	end if
end sub
 
private sub RegisterProcs()
	' Newest cams (Dryos rel 43 and later) only have System.Create()
	' on older dryos cams SystemEventInit is an alias for System.Create()
	' ExecuteEventProcedure does is not registered by default on vx, 
	' but calling an unregistered is not fatal
	if System.Create() = -1 then
		SystemEventInit()
	end if
	if ExecuteEventProcedure("UI_RegistDebugEventProc") = -1 then
		ExecuteEventProcedure("UI.CreatePublic")
	end if
end sub
 
private sub InitMsg()
	lcdmsg = ExecuteEventProcedure("LCDMsg_Create",10,10,"Started",2)
	if lcdmsg >= 0 then
		LCDMsg_ChangeColor(lcdmsg,2)
	end if
	msgstr = AllocateMemory(80)
	' truncate log
	msgfile = Fopen_Fut("A/CBDUMPER.LOG","w")
	if msgfile <> 0 then
		Fclose_Fut(msgfile)
	end if
end sub
 
private sub PutMsg(msg)
	if lcdmsg >= 0 then
		LCDMsg_SetStr(lcdmsg,msg,0)
	end if
	msgfile = Fopen_Fut("A/CBDUMPER.LOG","a")
	if msgfile <> 0 then
		Fwrite_Fut(msg,strlen(msg),1,msgfile)
		Fwrite_Fut("\n",1,1,msgfile)
		Fclose_Fut(msgfile)
	end if
end sub
 
private sub Initialize()
	RegisterProcs()
	InitMsg()
	PutMsg("Started")
 
	GetStart()
 
	if startaddr <> 0 then
		sprintf(msgstr,"%0X %s",startaddr,os)
		PutMsg(msgstr)
		if romsize = 0 then
			romsize = 0xFFFFFFFC - startaddr
		end if
		dumpfile = Fopen_Fut("A/PRIMARY.BIN","w")
		if dumpfile <> 0 then
			Fwrite_Fut(startaddr,romsize,1,dumpfile)
			Fclose_Fut(dumpfile)
			Wait(500)
			PutMsg("done")
		else
			PutMsg("file error")
		end if
	else
		sprintf(msgstr,"proxy found at %0X",foundaddr)
		PutMsg(msgstr)
		PutMsg("Firmware start not found!")
	end if
	FreeMemory(msgstr)
end sub
