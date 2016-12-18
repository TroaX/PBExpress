; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;
; PBExpress FastCGI Webframework
; By TroaX
; PB-Version 5.50
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;


; -----------------------------------------------------------------------------------------;
; Constants to Setup the Framework
; -----------------------------------------------------------------------------------------;
Enumeration
  #PBExpress_ContentLength = 100
  #PBExpress_ContentFormat
  #PBExpress_RAWString
  #PBExpress_Json
  #PBExpress_Post
  #PBExpress_JsonPost
EndEnumeration

; ========================================================================================;
; The Hash for the Route-ID
; ========================================================================================;
UseMD5Fingerprint()

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
  Declare.b SetOption(Option.i,Value.i)
  Declare.b RunServer()
  Declare.b SetDefaultPage(cacllback.i)
EndDeclareModule

; ========================================================================================;
; The PBExpress-Module
; ========================================================================================;
Module PBExpress
  ; -----------------------------------------------------------------------------------------;
  ; Basic Initializing for important constructs
  ; -----------------------------------------------------------------------------------------;
  EnableExplicit
  Prototype.i Routeapp(Map Request.s(),Map Post.s())
  NewList Keys.s()
  NewMap Routes.i()
  Define DefaultPage.RouteApp
  
  ; -----------------------------------------------------------------------------------------;
  ; Constants to Setup the Framework
  ; -----------------------------------------------------------------------------------------;
  Enumeration
    #PBExpress_ContentLength = 100
    #PBExpress_ContentFormat
    #PBExpress_RAWString
    #PBExpress_Json
    #PBExpress_Post
    #PBExpress_JsonPost
  EndEnumeration
  
  ; -----------------------------------------------------------------------------------------;
  ; Configuration-Structure
  ; -----------------------------------------------------------------------------------------;
  Structure PBEConfig
    ContentLength.i
    ContentFormat.i
  EndStructure
  
  Define Config.PBEConfig
  Config\ContentLength = 131072               ; Default: 128 KB
  Config\ContentFormat = #PBExpress_JsonPost  ; Default: JSON and Post (URL-Encoded Key-Value) allowed
  
  ; -----------------------------------------------------------------------------------------;
  ; Procedure to Change Settings
  ; -----------------------------------------------------------------------------------------;
  Procedure.b SetOption(Option.i, Value.i)
    Shared Config
    Select Option
      Case #PBExpress_ContentLength
        If Value < 10240
          Config\ContentLength = Value * 1024
          ProcedureReturn #True
        Else
          ProcedureReturn #False
        EndIf
      Case #PBExpress_ContentFormat
        Select Value
          Case #PBExpress_Json
            Config\ContentFormat = #PBExpress_Json
            ProcedureReturn #True
          Case #PBExpress_JsonPost
            Config\ContentFormat = #PBExpress_JsonPost
            ProcedureReturn #True
          Case #PBExpress_Post
            Config\ContentFormat = #PBExpress_Post
            ProcedureReturn #True
          Case #PBExpress_RAWString
            Config\ContentFormat = #PBExpress_RAWString
            ProcedureReturn #True
          Default
            ProcedureReturn #False
        EndSelect
      Default
        ProcedureReturn #False
    EndSelect
  EndProcedure
  
  
  ; -----------------------------------------------------------------------------------------;
  ; Procedure to Parse Routes with an Fake URL and the HTTP-Library
  ; -----------------------------------------------------------------------------------------;
  Procedure.s ParseKeys(strtoparse.s)
    Define fakeurl.s = "a://b.c/?" + strtoparse
    Shared Keys()
    Define routestring.s = ""
    ForEach Keys()
      routestring + Keys() + ":" + GetURLPart(fakeurl,Keys()) + ";"
    Next
    ProcedureReturn StringFingerprint(routestring,#PB_Cipher_MD5)
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
      Define routestring.s = ParseKeys(route)
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
    Shared Config
    Shared Routes()
    Shared DefaultPage
    NewMap Request.s()
    NewMap Post.s()
    Define.i CntLen, BufferLen
    Define.s RequestType, CalledRoute, ContentType
    
    While WaitFastCGIRequest()
      BufferLen = ReadCGI()
      If BufferLen
        ; #### Get Operation Header-Data #### ;
        CntLen = Val(CGIVariable(#PB_CGI_ContentLength))
        RequestType = CGIVariable(#PB_CGI_RequestMethod)
        CalledRoute = CGIVariable(#PB_CGI_QueryString)
        ContentType = CGIVariable(#PB_CGI_ContentType)
        
        Debug ContentType
        
        ; #### Check the Length of the Request-Body #### ;
        If CntLen > Config\ContentLength
          WriteCGIHeader(#PB_CGI_HeaderStatus, "413", #PB_CGI_LastHeader)
          WriteCGIStringN("<h1>413</h1><p>Request Entity Too Large: The Requestbody-Limit is " + Str(Config\ContentLength) + " Bytes</p>")
          Continue
        EndIf
        
        If (RequestType = "POST" Or RequestType = "PUT" Or RequestType = "PATCH") And CntLen > 0
          Define.s PostString = Right(PeekS(CGIBuffer(),BufferLen,#PB_Ascii),CntLen)
          
          ; #### Check JSON #### ;
          If (Config\ContentFormat = #PBExpress_Json Or Config\ContentFormat = #PBExpress_JsonPost) And ContentType = "application/json"
            If ParseJSON(#PB_Any, PostString)
              FreeJSON(#PB_All)
              Post("JSON") = PostString
            Else
              WriteCGIHeader(#PB_CGI_HeaderStatus, "400", #PB_CGI_LastHeader)
              WriteCGIStringN("<h1>415</h1><p>Bad Request: application/json Data required. But given no valid JSON-String.</p>")
              Continue
            EndIf
          ElseIf (Config\ContentFormat = #PBExpress_Post Or Config\ContentFormat = #PBExpress_JsonPost) And ContentType = "application/x-www-form-urlencoded"
     
            ; #### Render Post-Data #### ;          
            Define.i CountData = CountString(PostString,"&")
            Define.i SnippetCount
            If CountData > 0
              Define c.i
              Define Snippet.s
              For c = 1 To CountData + 1
                Snippet = StringField(PostString,c,"&")
                SnippetCount = CountString(Snippet,"=")
                If SnippetCount < 1 Or SnippetCount > 1
                  Continue
                Else
                  Post(StringField(Snippet,1,"=")) = URLDecoder(StringField(Snippet,2,"="))
                EndIf
              Next
            Else
              SnippetCount = CountString(PostString,"=")
              If SnippetCount = 1
                Post(StringField(PostString,1,"=")) = URLDecoder(StringField(PostString,2,"="))
              EndIf
            EndIf
            PostString = ""   
            If MapSize(Post()) = 0
              WriteCGIHeader(#PB_CGI_HeaderStatus, "400", #PB_CGI_LastHeader)
              WriteCGIStringN("<h1>415</h1><p>Bad Request: application/x-www-form-urlencoded Data required. But given no valid Key-Value URL-Encoded Datatable.</p>")
              Continue
            EndIf
          ElseIf Config\ContentFormat = #PBExpress_RAWString
            
            ; Important: Use the RAW-Configuration at your own Risc!
            Post("RAW") = PostString
          Else
            WriteCGIHeader(#PB_CGI_HeaderStatus, "400", #PB_CGI_LastHeader)
            WriteCGIStringN("<h1>415</h1><p>Bad Request: The Complete Request isn't valid!.</p>")
            Continue
          EndIf
        EndIf
        
        ; #### Get HTTP-Requestheader-Data ####;
        Request("AuthType") = CGIVariable(#PB_CGI_AuthType)
        Request("ContentLength") = Str(CntLen.i)
        Request("ContentType") = ContentType
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
          Define ParsedRoute.s = ParseKeys(CalledRoute)
          If ParsedRoute = ""
            WriteCGIHeader(#PB_CGI_HeaderStatus, "404", #PB_CGI_LastHeader)
            WriteCGIStringN("<h1>404</h1><p>Website Not found</p>")
          Else
            If FindMapElement(Routes(),ParsedRoute)
              Define app.RouteApp = Routes(ParsedRoute)
              app(Request(),Post())
            Else
              WriteCGIHeader(#PB_CGI_HeaderStatus, "404", #PB_CGI_LastHeader)
              WriteCGIStringN("<h1>404</h1><p>Website Not found</p>")
            EndIf
          EndIf
        EndIf
      EndIf
      BufferLen = 0
      CntLen = 0
      RequestType = ""
      CalledRoute = ""
      ClearMap(Request())
      ClearMap(Post())
    Wend
  EndProcedure
EndModule
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 35
; FirstLine = 9
; Folding = --
; EnableUnicode
; EnableThread
; EnableXP
; CompileSourceDirectory