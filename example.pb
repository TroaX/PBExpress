EnableExplicit

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
Procedure DefaultTest(Map Request.s(), Map Get.s(), Map Post.s(), Map Files.PBEFiles())
  PBExpress::SetCookie("DO_IT","RUN!",Date()+3600,#False,#True)
  PBExpress::Header(#PB_CGI_HeaderContentType, "text/html", #PB_UTF8 | #PB_CGI_LastHeader)
  Define ReturnStr.s
  ReturnStr = "<!DOCTYPE html>"
  ReturnStr + "<html lang="+Chr(34)+"de"+Chr(34)+">"
  ReturnStr + "<head>"
  ReturnStr + "<meta charset="+Chr(34)+"utf-8"+Chr(34)+">"
  ReturnStr + "<title>PBExpress Example</title>"
  ReturnStr + "</head>"
  ReturnStr + "<body>"
  ReturnStr + "<h2>Header-Daten</h2><pre>"
  ForEach Request()
    ReturnStr + MapKey(Request()) + ": " + Request() + "<br>"
  Next
  ReturnStr + "</pre>"
  ReturnStr + "<h2>Anzahl übergebene Daten</h2><pre>"
  ReturnStr + "GET: " + Str(MapSize(Get())) + "<br>"
  ReturnStr + "POST: " + Str(MapSize(Post())) + "<br>"
  ReturnStr + "Files: " + Str(MapSize(Files())) + "<br>"
  ReturnStr + "</pre>"
  ReturnStr + "</body>"
  PBExpress::Output(ReturnStr)
EndProcedure  

; ---- The PBExpress Options ---- ;
PBExpress::SetDefaultPage(@DefaultTest())                   ; Set Default Page-Procedure
PBExpress::AddRouteKey("mod")                               ; Set a Parameterkey for Routings
PBExpress::AddRouteKey("action")                            ; A Second one
PBExpress::AddRoute("mod=users&action=view",@DefaultTest()) ; Create a Route with Values to the defined Keys (In the Routingtable the Pointer saves under the combined Values hashed with MD5)

; ---- Start the Server ---- ;
PBExpress::RunServer()                                      ; Execute the Server

  
  
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 42
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP
; CompileSourceDirectory