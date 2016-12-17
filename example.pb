; ---- Load The Framework ---- ;
IncludeFile "pbexpress.pb"

; ---- Init CGI ---- ;
If Not InitCGI()
  End
EndIf

; ---- Init FastCGI ---- ;
If Not InitFastCGI(2005)
  End
EndIf

; ---- A Demonstration Page-Procedure ---- ;
Procedure DefaultTest(Map Request.s(),Map Post.s())
  WriteCGIHeader(#PB_CGI_HeaderContentType, "text/html", #PB_CGI_LastHeader)
  ReturnStr.s = "<h2>Header-Data</h2><pre>"
  ForEach Request()
    ReturnStr + MapKey(Request()) + ": " + Request() + "<br>"
  Next
  ReturnStr + "</pre>"
  If MapSize(Post()) > 0
    ReturnStr + "<h2>Post-Data</h2><pre>"
    ForEach Post()
      ReturnStr + MapKey(Post()) + ": " + Post() + "<br>"
    Next
    ReturnStr + "</pre>"
  EndIf
  WriteCGIStringN(ReturnStr)
EndProcedure  

; ---- The PBExpress Options ---- ;
PBExpress::SetDefaultPage(@DefaultTest()) ; Set Default Page-Procedure
PBExpress::AddRouteKey("mod")             ; Set a Parameterkey for Routings
PBExpress::AddRouteKey("action")          ; A Second one
PBExpress::AddRoute("mod=users&action=view",@DefaultTest()) ; Create a Route with Values to the defined Keys (In the Routingtable the Pointer saves under the combined Values ex. usersview)
PBExpress::RunServer()                    ; Execute the Server
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 36
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP
; CompileSourceDirectory