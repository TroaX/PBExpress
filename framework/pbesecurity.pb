; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;
; PBExpress FastCGI Webframework - FileSession
; By TroaX aká reVerB - 2016
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;

; -----------------------------------------------------------------------------------------;
; Module-Declaration
; -----------------------------------------------------------------------------------------;
DeclareModule PBESecurity
  Declare.s HTMLSpecialChars(Input.s)
  Declare.s SQLEscaping(Input.s)
  Declare.s GenerateSecureID(Data1.s = "DefaultData")
  Declare.s PasswordHash(Password.s,Salt.s = "",Coast.i = 300000)
  Declare.b PasswordVerify(Password.s,HashedString.s)
  Declare.s GenerateSecureString(Count.i = 16)
  Declare.s GeneratePassword(Count.i = 12)
EndDeclareModule

; -----------------------------------------------------------------------------------------;
; Begin Module
; -----------------------------------------------------------------------------------------;
Module PBESecurity
  ; -----------------------------------------------------------------------------------------;
  ; Private-Procedure for XOR 2 Hashes
  ; -----------------------------------------------------------------------------------------;
  Global Dim HexTable.a(127)
  Define.i i
  For i='0' To '9'
    HexTable(i)=(i-'0')
  Next
  For i='a' To 'f'
    HexTable(i)=(i-'a'+10)
  Next
  For i='A' To 'F'
    HexTable(i)=(i-'A'+10)
  Next
  For i=0 To 15
    HexTable(i)=Asc(Hex(i))
  Next
  
  Procedure HashXOR(*retchar.character,*achar.character,*bchar.character)
    While *achar\c>0
      *retchar\c=HexTable((HexTable(*achar\c&$7f)) ! (HexTable(*bchar\c&$7f)))
      *achar+SizeOf(character)
      *bchar+SizeOf(character)
      *retchar+SizeOf(character)
    Wend
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Init Fingerprints for Passwordhashing
  ; -----------------------------------------------------------------------------------------;
  UseSHA3Fingerprint()
  
  ; -----------------------------------------------------------------------------------------;
  ; Search/Replace Structure for HTMLSpecialChars
  ; -----------------------------------------------------------------------------------------;
  Structure Pattern
    Search.s
    Replace.s
  EndStructure
  
  ; -----------------------------------------------------------------------------------------;
  ; Build a List with SpecialChars
  ; -----------------------------------------------------------------------------------------;
  NewList Specials.Pattern()
  AddElement(Specials())
  Specials()\Search  = "&"
  Specials()\Replace = "&amp;"
  AddElement(Specials())
  Specials()\Search  = "<"
  Specials()\Replace = "&lt;"
  AddElement(Specials())
  Specials()\Search  = ">"
  Specials()\Replace = "&gt;"
  AddElement(Specials())
  Specials()\Search  = "'"
  Specials()\Replace = "&apos;"
  AddElement(Specials())
  Specials()\Search  = Chr(34)
  Specials()\Replace = "&quot;"
  
  ; -----------------------------------------------------------------------------------------;
  ; Generate Secure ID for Cookies, Sessions or XSRF (CSRF)
  ; -----------------------------------------------------------------------------------------;
  Procedure.s GenerateSecureID(Data1.s = "DefaultData")
    Define.s Data2, Data3, Data4
    Define *Cache
    If OpenCryptRandom()
      Data2 = Str(Date())
      Data3 = Str(100000000 + CryptRandom(89999999))
      *Cache = AllocateMemory(64)
      Data4 = Space(87)
      CryptRandomData(*Cache,64)
      Base64Encoder(*Cache,64,@Data4,87,#PB_Cipher_NoPadding)
      Data4 = PeekS(@Data4,87,#PB_Ascii)
      CloseCryptRandom()
      ProcedureReturn StringFingerprint(Data1+Data2+Data3+Data4,#PB_Cipher_SHA3,256,#PB_UTF8)
    Else
      ProcedureReturn ""
    EndIf
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Generate a Secure Password
  ; -----------------------------------------------------------------------------------------;
  Procedure.s GeneratePassword(Count.i = 12)
    If OpenCryptRandom()
      Define.s InitString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-=#$%&!?=#$ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-=#$%&!?=#$"
      If Count = 0
        Count = 8 + CryptRandom(16)
      EndIf
      Define ReturnString.s = ""
      Dim ranchar.c(9)
      Define x.i
      Define.i Length = Len(InitString)
      For x = 1 To Count
        ReturnString + Mid(InitString,CryptRandom(Length - 1)+1,1)
      Next
      CloseCryptRandom()
      ProcedureReturn ReturnString
    Else
      ProcedureReturn ""
    EndIf
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; SpecialChars-Procedure
  ; -----------------------------------------------------------------------------------------;
  Procedure.s HTMLSpecialChars(Input.s)
    Shared Specials()
    ForEach Specials()
      Input = ReplaceString(Input,Specials()\Search,Specials()\Replace)
    Next
    ProcedureReturn Input
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Escape a String for SQL
  ; -----------------------------------------------------------------------------------------;
  Procedure.s SQLEscaping(Input.s)
    Input = EscapeString(Input)
    Input = ReplaceString(Input,"'","\'")
    Input = RemoveString(Input,Chr(0))
    ProcedureReturn Input
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Generate a Random String (More Special-Chars as Password Generating)
  ; -----------------------------------------------------------------------------------------;
  Procedure.s GenerateSecureString(Count.i = 16)
    If OpenCryptRandom()
      Define.i Counter,Random
      Define.s Salt = ""
      For Counter = 0 To Count - 1
        Random = CryptRandom(81)
        Select Random
            Case 0 To 30
              Salt + Chr(Random + 33)
            Case 31 To 55
              Salt + Chr(Random + 34)
            Case 57 To 81
              Salt + Chr(Random + 40)
        EndSelect
      Next Counter
      ProcedureReturn Salt
    EndIf
    ProcedureReturn ""
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Private Hash-Procedure
  ; -----------------------------------------------------------------------------------------;
  Procedure.s PBKDF2(Hash.i,Bits.i,Password.s,Salt.s,Coast.i)
    Define.s HashA,HashB,PreString
    Define.i Counter,Bytes
    PreString = Password + Salt
    Define *Buffer = AllocateMemory(Len(PreString) * 6)
    Bytes = PokeS(*Buffer, PreString,-1,#PB_UTF8)
    HashA = Fingerprint(*Buffer,bytes,Hash,Bits)
    For Counter = 1 To Coast
      Bytes = PokeS(*buffer,HashA,-1,#PB_UTF8)
      HashB = Fingerprint(*Buffer,Bytes,Hash,Bits)
      HashXOR(@HashA,@HashA,@HashB)
    Next Counter
    ProcedureReturn HashA
  EndProcedure

  ; -----------------------------------------------------------------------------------------;
  ; Public Hash-Procedure
  ; -----------------------------------------------------------------------------------------;
  Procedure.s PasswordHash(Password.s,Salt.s = "",Coast.i = 300000)
    Define.i Algo = #PB_Cipher_SHA3
    Define.i Size = 256
    Define.s PWHash
    If Len(Salt) = 0
      Salt = GeneratePassword(0)
    EndIf
    Salt = RemoveString(Salt,"|")
    PWHash = PBKDF2(Algo,Size,Password,Salt,Coast)
    ProcedureReturn Str(Algo)+"|"+Str(Size)+"|"+Str(Coast)+"|"+PWHash+"|"+Salt
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Procedure to Verify a Hash-String (given by PasswordHash) and a Password
  ; -----------------------------------------------------------------------------------------;
  Procedure.b PasswordVerify(Password.s,HashedString.s)
    If CountString(HashedString,"|") = 4
      Define.i Algo,Size,Coast
      Define.s Salt,ExtractedHash,CompareHash
      Algo = Val(StringField(HashedString,1,"|"))
      Size = Val(StringField(HashedString,2,"|"))
      Coast = Val(StringField(HashedString,3,"|"))
      ExtractedHash = StringField(HashedString,4,"|")
      Salt = StringField(HashedString,5,"|")
      CompareHash = PBKDF2(Algo,Size,Password,Salt,Coast)
      If ExtractedHash = CompareHash
        ProcedureReturn #True
      Else
        ProcedureReturn #False
      EndIf
    Else
      ProcedureReturn #False
    EndIf
  EndProcedure
EndModule
; IDE Options = PureBasic 5.51 (Windows - x64)
; CursorPosition = 47
; FirstLine = 24
; Folding = --
; EnableThread
; EnableXP
; CompileSourceDirectory
; Compiler = PureBasic 5.51 (Windows - x64)
; EnableUnicode