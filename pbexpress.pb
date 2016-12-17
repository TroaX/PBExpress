; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;
; PBExpress FastCGI Webframework
; By TroaX
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;


; ========================================================================================;
; Regular Expression for forbidden Signs
; ========================================================================================;
CreateRegularExpression(1001,"[\s\W]",#PB_RegularExpression_NoCase)

; ========================================================================================;
; PBExpress-Module Declararion
; ========================================================================================;
DeclareModule PBExpress
  Declare.b AddRouteKey(keystring.s)
  Declare.b AddRoute(route.s,callback.i)
  Declare.b RunServer()
  Declare.b SetDefaultPage(cacllback.i)
EndDeclareModule

; ========================================================================================;
; The PBExpress-Module
; ========================================================================================;
Module PBExpress
  Prototype.i Routeapp(Map Request.s(),Map Post.s())
  NewList Keys.s()
  NewMap Routes.i()
  DefaultPage.RouteApp
  
  ; -----------------------------------------------------------------------------------------;
  ; Procedure to Parse Routes with an Fake URL and the HTTP-Library
  ; -----------------------------------------------------------------------------------------;
  Procedure.s ParseKeys(strtoparse.s)
    fakeurl.s = "a://b.c/?" + strtoparse
    Shared Keys()
    routestring.s = ""
    ForEach Keys()
      routestring + GetURLPart(fakeurl,Keys())
    Next
    ProcedureReturn routestring
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Procedure to Set the Default-Page
  ; -----------------------------------------------------------------------------------------;
  Procedure.b SetDefaultPage(callback.i)
    Shared DefaultPage
    If callback > 0
      DefaultPage = callback
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Add a Route-Key to use for the Routeparser
  ; -----------------------------------------------------------------------------------------;
  Procedure.b AddRouteKey(keystring.s)
    Shared Keys()
    If Not MatchRegularExpression(1001,keystring)
      AddElement(Keys()) : Keys() = keystring
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Add a Route to the Routing-Table
  ; -----------------------------------------------------------------------------------------;
  Procedure.b AddRoute(route.s,callback.i)
    Shared Keys()
    Shared Routes.i()
    If ListSize(Keys()) > 0
      routestring.s = ParseKeys(route)
      If Not routestring = ""
        Routes(routestring) = callback
        ProcedureReturn #True
      Else
        ProcedureReturn #False
      EndIf
    Else
      ProcedureReturn #False
    EndIf
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Run the Server
  ; -----------------------------------------------------------------------------------------;
  Procedure.b RunServer()
    Shared Routes()
    Shared DefaultPage
    NewMap Request.s()
    NewMap Post.s()
    
    While WaitFastCGIRequest()
      BufferLen.i = ReadCGI()
      If BufferLen
        ; #### Get Operation Header-Data #### ;
        CntLen.i = Val(CGIVariable(#PB_CGI_ContentLength))
        RequestType.s = CGIVariable(#PB_CGI_RequestMethod)
        CalledRoute.s = CGIVariable(#PB_CGI_QueryString)
        
        ; #### Get HTTP-Requestheader-Data ####;
        If (RequestType = "POST" Or RequestType = "PUT" Or RequestType = "PATCH") And CntLen > 0
          PostString.s = Right(PeekS(CGIBuffer(),BufferLen,#PB_Ascii),CntLen)
          
          ; #### Render Post-Data #### ;
          CountData.i = CountString(PostString,"&")
          If CountData > 0
            For c = 1 To CountData + 1
              Snippet.s = StringField(PostString,c,"&")
              Post(StringField(Snippet,1,"=")) = URLDecoder(StringField(Snippet,2,"="))
            Next
          Else
            Post(StringField(PostString,1,"=")) = URLDecoder(StringField(PostString,2,"="))
          EndIf
          PostString = ""
        EndIf
        Request("AuthType") = CGIVariable(#PB_CGI_AuthType)
        Request("ContentLength") = Str(CntLen.i)
        Request("DocumentRoot") = CGIVariable(#PB_CGI_DocumentRoot)
        Request("GatewayInterface") = CGIVariable(#PB_CGI_GatewayInterface)
        Request("PathInfo") = CGIVariable(#PB_CGI_PathInfo)
        Request("PathTranslated") = CGIVariable(#PB_CGI_PathTranslated)
        Request("QueryString") = CalledRoute
        Request("RemoteAddr") = CGIVariable(#PB_CGI_RemoteAddr)
        Request("RemoteHost") = CGIVariable(#PB_CGI_RemoteHost)
        Request("RemoteIdent") = CGIVariable(#PB_CGI_RemoteIdent)
        Request("RemotePort") = CGIVariable(#PB_CGI_RemotePort)
        Request("RemoteUser") = CGIVariable(#PB_CGI_RemoteUser)
        Request("RequestURI") = CGIVariable(#PB_CGI_RequestURI)
        Request("RequestMethod") = RequestType
        Request("ScriptName") = CGIVariable(#PB_CGI_ScriptName)
        Request("ServerAdmin") = CGIVariable(#PB_CGI_ServerAdmin)
        Request("ServerName") = CGIVariable(#PB_CGI_ServerName)
        Request("ServerPort") = CGIVariable(#PB_CGI_ServerPort)
        Request("ServerProtocol") = CGIVariable(#PB_CGI_ServerProtocol)
        Request("ServerSignature") = CGIVariable(#PB_CGI_ServerSignature)
        Request("ServerSoftware") = CGIVariable(#PB_CGI_ServerSoftware)
        Request("HttpAccept") = CGIVariable(#PB_CGI_HttpAccept)
        Request("HttpAcceptEncoding") = CGIVariable(#PB_CGI_HttpAcceptEncoding)
        Request("HttpAcceptLanguage") = CGIVariable(#PB_CGI_HttpAcceptLanguage)
        Request("HttpCookie") = CGIVariable(#PB_CGI_HttpCookie)
        Request("HttpForwarded") = CGIVariable(#PB_CGI_HttpForwarded)
        Request("HttpHost") = CGIVariable(#PB_CGI_HttpHost)
        Request("HttpPragma") = CGIVariable(#PB_CGI_HttpPragma)
        Request("HttpReferer") = CGIVariable(#PB_CGI_HttpReferer)
        Request("HttpUserAgent") = CGIVariable(#PB_CGI_HttpUserAgent)
        
        If CalledRoute = ""
          DefaultPage(Request(),Post())
        Else
          ParsedRoute.s = ParseKeys(CalledRoute)
          If ParsedRoute = ""
            WriteCGIHeader(#PB_CGI_HeaderStatus, "404", #PB_CGI_LastHeader)
            WriteCGIStringN("<h1>404</h1><p>Website Not found</p>")
          Else
            If FindMapElement(Routes(),ParsedRoute)
              app.RouteApp = Routes(ParsedRoute)
              app(Request(),Post())
            Else
              WriteCGIHeader(#PB_CGI_HeaderStatus, "404", #PB_CGI_LastHeader)
              WriteCGIStringN("<h1>404</h1><p>Website Not found</p>")
            EndIf
          EndIf
        EndIf
      EndIf
      ClearMap(Request())
      ClearMap(Post())
    Wend
  EndProcedure
EndModule
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 3
; Folding = --
; EnableUnicode
; EnableThread
; EnableXP
; CompileSourceDirectory
