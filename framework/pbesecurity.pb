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
  Declare.s PasswordHash(Password.s,Salt.s = "",Coast.i = 25000)
  Declare.b PasswordVerify(Password.s,HashedString.s)
  Declare.s GenerateSecureString(Count.i = 16)
  Declare.s GeneratePassword(Count.i = 12)
EndDeclareModule

; -----------------------------------------------------------------------------------------;
; Begin Module
; -----------------------------------------------------------------------------------------;
Module PBESecurity
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
  Specials()\Search  = Chr(34)
  Specials()\Replace = "&quot;"
  
  ; -----------------------------------------------------------------------------------------;
  ; Init Fingerprints for Passwordhashing
  ; -----------------------------------------------------------------------------------------;
  UseSHA3Fingerprint()
  UseSHA1Fingerprint()
  UseSHA2Fingerprint()
  UseMD5Fingerprint()
  
  ; -----------------------------------------------------------------------------------------;
  ; Private-Procedure for XOR 2 Hashes
  ; -----------------------------------------------------------------------------------------;
  Procedure.s HashXOR(HashA.s,HashB.s)
    Define.i ByteLenA,ByteLenB
    ByteLenA = Len(HashA)
    ByteLenB = Len(HashB)
    If ByteLenA = ByteLenB
      Define.s NewHash
      Define.i Counter
      Define.b ByteA,ByteB
      For Counter = 0 To ByteLenA -1
        ByteA = Val("$"+Mid(HashA,Counter,1))
        ByteB = Val("$"+Mid(HashB,Counter,1))
        NewHash + Hex(ByteA ! ByteB)
      Next
      ProcedureReturn LCase(NewHash)
    Else
      ProcedureReturn ""
    EndIf
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Generate Secure ID for Cookies, Sessions or XSRF (CSRF)
  ; -----------------------------------------------------------------------------------------;
  Procedure.s GenerateSecureID(Data1.s = "DefaultData")
    Define.s Data2, Data3
    If OpenCryptRandom()
      Data2 = Str(Date())
      Data3 = Str(100000000 + CryptRandom(89999999))
      CloseCryptRandom()
    EndIf
    ProcedureReturn StringFingerprint(Data1+Data2+Data3,#PB_Cipher_SHA3,224,#PB_UTF8)
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Generate a Secure Password
  ; -----------------------------------------------------------------------------------------;
  Procedure.s GeneratePassword(Count.i = 12)
    If OpenCryptRandom()
      If Count = 0
        Count = 6 + CryptRandom(16)
      EndIf
      Define ReturnString.s = ""
      Dim ranchar.c(6)
      Define x.i
      For x = 1 To Count
        ranchar(0) = CryptRandom(3) + 35
        ranchar(1) = CryptRandom(9) + 48
        ranchar(2) = CryptRandom(25) + 65
        ranchar(3) = CryptRandom(25) + 65
        ranchar(4) = CryptRandom(25) + 97
        ranchar(5) = CryptRandom(25) + 97
        ranchar(6) = CryptRandom(2) + 45
        ReturnString + Chr(ranchar(Random(6,0)))
      Next
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
    Define.s HashA,HashB,PWandSalt,Finished
    Define.i Counter
    PWandSalt = Password + Salt
    For Counter = 1 To Coast
      HashA = StringFingerprint(PWandSalt,Hash,Bits,#PB_UTF8)
      HashB = StringFingerprint(HashA,Hash,Bits,#PB_UTF8)
      PWandSalt = HashXOR(HashA,HashB)
    Next Counter
    ProcedureReturn PWandSalt
  EndProcedure
  
  ; -----------------------------------------------------------------------------------------;
  ; Public Hash-Procedure
  ; -----------------------------------------------------------------------------------------;
  Procedure.s PasswordHash(Password.s,Salt.s = "",Coast.i = 25000)
    Define.i Algo = #PB_Cipher_SHA3
    Define.i Size = 256
    Define.s PWHash
    If Len(Salt) = 0
      Salt = GenerateSecureString(16)
    EndIf
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

OpenConsole()
Repeat
  PrintN(PBESecurity::GeneratePassword())
  Tzzz.s = Input()
Until Tzzz = "x"

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 216
; FirstLine = 172
; Folding = --
; EnableUnicode
; EnableThread
; EnableXP
; CompileSourceDirectory