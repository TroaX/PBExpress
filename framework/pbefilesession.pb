; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;
; PBExpress FastCGI Webframework - FileSession
; By TroaX aká reVerB - 2016
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;

; -----------------------------------------------------------------------------------------;
; Detect the correct Path-Separator
; -----------------------------------------------------------------------------------------;
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #PATH_SEPARATOR = "\"
CompilerElse
  #PATH_SEPARATOR = "/"
CompilerEndIf

; -----------------------------------------------------------------------------------------;
; Module Declaration
; -----------------------------------------------------------------------------------------;
DeclareModule PBEFileSession
  Declare.b LoadSession(Session.s)
  Declare.b StartSession()
  Declare.b SetSessionValue(Key.s,Value.s)
  Declare.s GetSessionValue(Key.s)
  Declare.b GetSessionList(Key.s,List SessList.s())
  Declare.b SetSessionList(Key.s,List SessList.s())
  Declare.b CloseSession()
  Declare.s SessionID()
  Declare.b SetSessionDirectory(Directory.s)
  Declare.b DestroySession(key.s)
EndDeclareModule

; -----------------------------------------------------------------------------------------;
; The Module
; -----------------------------------------------------------------------------------------;
Module PBEFileSession
  ; -----------------------------------------------------------------------------------------;
  ; Detect the correct Path-Separator
  ; -----------------------------------------------------------------------------------------;
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    #PATH_SEPARATOR = "\"
  CompilerElse
    #PATH_SEPARATOR = "/"
  CompilerEndIf
  
  ; -----------------------------------------------------------------------------------------;
  ; Set the Module-Global Variables and Lists
  ; -----------------------------------------------------------------------------------------;
  NewMap Session.s()
  NewMap SessionLists.s()
  Define.s SessionID,SessionDirectory
  
  ; -----------------------------------------------------------------------------------------;
  ; Set the Default Directory
  ; -----------------------------------------------------------------------------------------;
  SessionDirectory = GetCurrentDirectory()+#PATH_SEPARATOR+"Sessions"
  
  ; -----------------------------------------------------------------------------------------;
  ; Start Fingerprint
  ; -----------------------------------------------------------------------------------------;
  UseSHA3Fingerprint()
  
  ; -----------------------------------------------------------------------------------------;
  ; Expression For forbidden Signs
  ; -----------------------------------------------------------------------------------------;
  CreateRegularExpression(1001,"[\s\W]",#PB_RegularExpression_NoCase)
  
  ; -----------------------------------------------------------------------------------------;
  ; Procedure to Load the Session-File from SessionDirectory
  ; -----------------------------------------------------------------------------------------;
  Procedure.b LoadSession(Session.s)
    Shared Session()
    Shared SessionLists()
    Shared SessionID
    Shared SessionDirectory
    If OpenFile(0, SessionDirectory+#PATH_SEPARATOR+Session+".sess")
      content.s = ReadString(0,#PB_File_IgnoreEOL)
      CloseFile(0)
      Rules.i = CountString(content,"+")
      If Rules
        Define.i c
        Define.s SnippetA
        Define.s SnippetB
        Define.s SnippetC
        For c = 1 To Rules + 1
          SnippetA = StringField(content,c,"+")
          SnippetB = StringField(SnippetA,1,">")
          SnippetC = StringField(SnippetA,2,">")
          If Left(SnippetB,1) = "§"
            SessionLists(Mid(SnippetB,2)) = SnippetC
          Else
            Session(SnippetB) = URLDecoder(SnippetC)
          EndIf
        Next c
      Else
        If CountString(content,">")
          If Left(StringField(content,1,">"),1) = "§"
            SessionLists(Mid(StringField(content,1,">"),2)) = URLDecoder(StringField(content,2,">"))
          Else
            Session(StringField(content,1,">")) = URLDecoder(StringField(content,2,">"))
          EndIf
        Else
          ProcedureReturn #False
        EndIf
      EndIf
      SessionID = Session
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Start a New Session if no Session currently exists
  ; -----------------------------------------------------------------------------------------;
  Procedure.b StartSession()
    *Key = AllocateMemory(32)
    Shared SessionID
    If Len(SessionID) > 20
      ProcedureReturn #True
    EndIf
    If OpenCryptRandom() And *Key
      CryptRandomData(*Key, 32)
      Define.s KeyString
      For i = 0 To 31
        KeyString + RSet(Hex(PeekB(*Key+i), #PB_Byte), 2, "0")
      Next i
      KeyString + Str(Date()) + Str(CryptRandom(999999))
      CloseCryptRandom()
      SessionID = StringFingerprint(KeyString, #PB_Cipher_SHA3,224)
    Else
      ProcedureReturn #False
    EndIf
    ProcedureReturn #True
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Write a New Value in the Session
  ; -----------------------------------------------------------------------------------------;
  Procedure.b SetSessionValue(Key.s,Value.s)
    Shared Session()
    If Not MatchRegularExpression(1001,Key)
      Session(Key) = Value
      ProcedureReturn #True
    EndIf
    ProcedureReturn #False
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Get a Value from the Session
  ; -----------------------------------------------------------------------------------------;
  Procedure.s GetSessionValue(Key.s)
    Shared Session()
    If Not MatchRegularExpression(1001,Key)
      If FindMapElement(Session(),Key)
        ProcedureReturn Session()
      EndIf
      ProcedureReturn ""
    EndIf
    ProcedureReturn ""
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Get a String-List to the current Session
  ; -----------------------------------------------------------------------------------------;
  Procedure.b GetSessionList(Key.s,List SessList.s())
    Shared SessionLists()
    If Not MatchRegularExpression(1001,Key)
      If FindMapElement(SessionLists(),Key)
        ClearList(SessList())
        Define.s Values = SessionLists()
        Define.i Entries = CountString(Values,"|")
        Define.i c
        For c = 1 To Entries + 1
          AddElement(SessList())
          SessList() = URLDecoder(StringField(Values,c,"|"))
        Next c
        ProcedureReturn #True
      EndIf
      ProcedureReturn #True
    EndIf
    ProcedureReturn #True
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Add a String-List to the current Session
  ; -----------------------------------------------------------------------------------------;
  Procedure.b SetSessionList(Key.s,List SessList.s())
    Shared SessionLists()
    Define.s Value
    If Not MatchRegularExpression(1001,Key)
      Define.i LSize = ListSize(SessList())
      If LSize > 0
        Define.i c
        For c = 0 To LSize - 1
          SelectElement(SessList(),c)
          Value + URLEncoder(SessList())
          If c < (LSize - 1)
            Value + "|"
          EndIf
        Next c  
        SessionLists(Key) = Value
        ProcedureReturn #True
      EndIf
      ProcedureReturn #False
    EndIf
    ProcedureReturn #False
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Close the Session and Write the current Session-Data to the Sessionfile
  ; -----------------------------------------------------------------------------------------;
  Procedure.b CloseSession()
    Shared Session()
    Shared SessionLists()
    Shared SessionID
    Define.i SessionSize = MapSize(Session())
    Define.i ListSize = MapSize(SessionLists())
    Define.s Compiled
    If SessionSize > 0
      ForEach Session()
        Compiled + MapKey(Session()) + ">" + URLDecoder(Session()) + "+" 
      Next
    EndIf
    If ListSize > 0
      ForEach SessionLists()
        Compiled + "§" + MapKey(SessionLists()) + ">" + SessionLists() + "+"
      Next
    EndIf
    If ListSize > 0 Or SessionSize > 0
      If CreateFile(0,GetCurrentDirectory()+"\Session\"+SessionID+".sess")
        WriteString(0,Left(Compiled,Len(Compiled)-1))
        CloseFile(0)
        ClearMap(Session())
        ClearMap(SessionLists())
        SessionID = ""
        ProcedureReturn #True
      EndIf
      ClearMap(Session())
      ClearMap(SessionLists())
      SessionID = ""
      ProcedureReturn #False
    EndIf
    ClearMap(Session())
    ClearMap(SessionLists())
    SessionID = ""
    ProcedureReturn #False
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Returned the Session-ID
  ; -----------------------------------------------------------------------------------------;
  Procedure.s SessionID()
    Shared SessionID
    ProcedureReturn SessionID
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Set the Session-Directory (Use this in a Global Context or Sort your Sessions in different Directories)
  ; -----------------------------------------------------------------------------------------;
  Procedure.b SetSessionDirectory(Directory.s)
    Shared SessionDirectory
    Define.i CheckDir
    CheckDir = ExamineDirectory(#PB_Any,Directory,"*.*")
    If CheckDir
      FinishDirectory(CheckDir)
      SessionDirectory = Directory
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Destroy a Session (this Delete the SessionFile)
  ; -----------------------------------------------------------------------------------------;
  Procedure.b DestroySession(key.s)
    Shared Session()
    Shared SessionLists()
    Shared SessionDirectory
    If DeleteFile(SessionDirectory+#PATH_SEPARATOR+key+".sess")
      ClearMap(Session())
      ClearMap(SessionLists())
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  EndProcedure
EndModule
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 2
; Folding = ---
; EnableUnicode
; EnableThread
; EnableXP
; CompileSourceDirectory