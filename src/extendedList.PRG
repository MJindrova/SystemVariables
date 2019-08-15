LPARAM m.lcOF

* lcOF - Output file

LOCAL m.lcPath, m.lcPom, m.lii, m.lihFile, m.liMax, m.llSame, m.llErr, m.lcErr, m.lcConfig
LOCAL m.liEL_VFP, m.lcEL_VFP, m.liEL_hFile, m.liEL_Count
LOCAL ARRAY m.laEL_Vars(1), m.laEL_Values(1), m.laEL_Types(1), m.laEL_DValues(1)

m.lcPath=SYS(16)
m.lcPath=IIF(RAT("\", m.lcPath)>0, LEFT(m.lcPath, RAT("\", m.lcPath)), m.lcPath)

*!* _Screen.Tag=lcPath
*!* DISPLAY MEMORY TO (_Screen.Tag+"..\out\a1.txt") NOCONSOLE

m.liEL_VFP=VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))

_Screen.Comment=m.lcPath+"..\out\save.mem"

m.lcEL_VFP=IIF(m.liEL_VFP<10, CHR(48+m.liEL_VFP), CHR(55+m.liEL_VFP))

IF EMPTY(m.lcOF)
   m.lcOF=m.lcPath+"..\out\"+PROGRAM()+"_"+m.lcEL_VFP+".md"
ENDIF


m.lcConfig=m.lcPath+"VFP"+m.lcEL_VFP+".list"
* Read config file
IF m.liEL_VFP>6
   * Read config file
   m.lcPom=FILETOSTR(m.lcConfig)
   IF EMPTY(m.lcPom)
      ?"Config file is empty"
      RETURN
   ENDIF
   m.liEL_Count=ALINES(m.laEL_Vars, m.lcPom)
ELSE
   m.lihFile=FOPEN(m.lcConfig)
   IF m.lihFile<=0 
      ?"Config file is empty"
      RETURN
   ENDIF
   m.liEL_Count=0
   DO WHILE NOT FEOF(m.lihFile)
      m.liEL_Count=m.liEL_Count+1
      DIMENSION m.laEL_Vars(m.liEL_Count)
      m.laEL_Vars(m.liEL_Count)=FGETS(m.lihFile)
   ENDDO
   =FCLOSE(m.lihFile)
ENDIF

m.liEL_hFile=FCREATE(m.lcOF)
IF m.liEL_hFile<=0
   ?"Cannot create output file"
   RETURN
ENDIF



=ASORT(m.laEL_Vars)
DIME m.laEL_Types(m.liEL_Count), m.laEL_Values(m.liEL_Count), m.laEL_DValues(m.liEL_Count)
m.lcErr=ON("ERROR")
ON ERROR m.llErr=.T.

FOR m.lii=1 TO m.liEL_Count
    *?m.lii, m.laEL_Vars(m.lii)

    m.laEL_Types(m.lii)=TYPE(m.laEL_Vars(m.lii))
    m.laEL_DValues(m.lii)=EVAL(m.laEL_Vars(m.lii))

    DO CASE
       CASE m.laEL_Types(m.lii)="O"
            m.laEL_Values(m.lii)=CREATEOBJECT("custom")

       CASE m.laEL_Types(m.lii)="C"
            m.laEL_Values(m.lii)=SYS(2015)

       CASE m.laEL_Types(m.lii)="N"
            m.laEL_Values(m.lii)=IIF(m.laEL_Vars(m.lii)="_TEXT", m.liEL_hFile, m.laEL_DValues(m.lii)+1)

       CASE m.laEL_Types(m.lii)="L"
            m.laEL_Values(m.lii)=!m.laEL_DValues(m.lii)

       CASE m.laEL_Types(m.lii)="D"
            m.laEL_Values(m.lii)=IIF(EMPTY(m.laEL_DValues(m.lii)), DATE(), {--})

       CASE m.laEL_Types(m.lii)="T"
            m.laEL_Values(m.lii)=IIF(EMPTY(m.laEL_DValues(m.lii)), DATETIME(), {--::})

    ENDCASE

    IF m.laEL_Types(m.lii)#"U"
       m.llErr=.F.
       STORE m.laEL_Values(m.lii) TO (m.laEL_Vars(m.lii))

       IF m.llErr && ERROR
          m.laEL_Types(m.lii)="E"
       ENDIF
       IF NOT m.llErr AND EVAL(m.laEL_Vars(m.lii))==m.laEL_DValues(m.lii) && ReadOnly
          m.laEL_Types(m.lii)="R"
       ENDIF
       IF m.laEL_Vars(m.lii)="_TEXT"
          _TEXT=m.laEL_DValues(m.lii) && this is workarround - START
          * if you set _TEXT to valid value 
          * - and set _THROTTLE to -1, then VFP close file associated with _TEXT value always
          * - and set _THROTTLE to >0, then VFP close file associated with _TEXT value sometime
       ENDIF
    ENDIF
    
NEXT
IF EMPTY(m.lcErr)
   ON ERROR
ELSE
   ON ERROR &lcErr.
ENDIF

SAVE TO (_Screen.Comment) ALL LIKE 'l?EL_*'
CLEAR ALL
*!* DISPLAY MEMORY TO (_Screen.Tag+"..\out\a2.txt") NOCONSOLE



**********************************************************************************************************************************
*
*
*
**********************************************************************************************************************************
RESTORE FROM (_Screen.Comment) ADDITIVE
LOCAL m.lii, m.lcPom, m.llSame, m.lcSAFETY, m.lcErr, m.llFirst
LOCAL ARRAY m.laEL_CValues(1)

m.lcSAFETY=SET("SAFETY")
SET SAFETY OFF
DELETE FILE (_Screen.Comment) 
SET SAFETY &lcSAFETY.

* GET current values
_TEXT=m.liEL_hFile && this is workarround - END

DIMENSION m.laEL_CValues(m.liEL_Count)
FOR m.lii=1 TO m.liEL_Count
    m.laEL_CValues(m.lii)=EVAL(m.laEL_Vars(m.lii))
NEXT

_PRETEXT="" && reset this value

SET CONSOLE OFF
SET TEXTMERGE ON
\\# System Variables in VFP <<m.lcEL_VFP>>

m.llFirst=.T.
FOR m.lii=1 TO ALEN(m.laEL_Vars)
    IF m.laEL_Types(m.lii)="R"
       IF m.llFirst
\## Read Only Variables
\| Name  | Type | Default Value |
\|:------------- |:------------- |:------------- |
          m.llFirst=.F.
       ENDIF
       m.lcPom=TYPE(m.laEL_Vars(m.lii))
       \| \<<m.laEL_Vars(m.lii)>> | <<m.lcPom>> | `<<IIF(m.lcPom="O", "Object", IIF(m.lcPom="C" AND EMPTY(m.laEL_DValues(m.lii)), ' ', m.laEL_DValues(m.lii)))>>` |
    ENDIF
NEXT

m.llFirst=.T.
FOR m.lii=1 TO ALEN(m.laEL_Vars)
    IF m.laEL_Types(m.lii)="E"
       IF m.llFirst
\
\* * *
\## Restricted Writing
\| Name  | Type | Default Value |
\|:------------- |:------------- |:------------- |
          m.llFirst=.F.
       ENDIF
       m.lcPom=TYPE(m.laEL_Vars(m.lii))
       \| \<<m.laEL_Vars(m.lii)>> | <<m.lcPom>> | `<<IIF(m.lcPom="O", "Object", IIF(m.lcPom="C" AND EMPTY(m.laEL_DValues(m.lii)), ' ', m.laEL_DValues(m.lii)))>>` |
    ENDIF
NEXT

m.llFirst=.T.
FOR m.lii=1 TO ALEN(m.laEL_Vars)
    IF !INLIST(m.laEL_Types(m.lii), "U", "R", "E")
       m.lcPom=m.laEL_Types(m.lii)
       m.llSame=IIF(m.lcPom="O", COMPOBJ(m.laEL_Values(m.lii) ,m.laEL_CValues(m.lii)), m.laEL_Values(m.lii)==m.laEL_CValues(m.lii))
       IF !m.llSame
          IF m.llFirst
\
\* * *
\## Autorefresh at CLEAR ALL
\| Name  | Type | Default Value |
\|:------------- |:------------- |:------------- |
             m.llFirst=.F.
          ENDIF
          \| \<<m.laEL_Vars(m.lii)>> | <<m.laEL_Types(m.lii)>> | `<<IIF(m.lcPom="O", "Object", IIF(m.lcPom="C" AND EMPTY(m.laEL_DValues(m.lii)), ' ', m.laEL_DValues(m.lii)))>>` |
       ENDIF
    ENDIF
NEXT

m.llFirst=.T.
FOR m.lii=1 TO ALEN(m.laEL_Vars)
    IF !INLIST(m.laEL_Types(m.lii), "U", "R", "E")
       m.lcPom=m.laEL_Types(m.lii)
       m.llSame=IIF(m.lcPom="O", COMPOBJ(m.laEL_Values(m.lii), m.laEL_CValues(m.lii)), m.laEL_Values(m.lii)==m.laEL_CValues(m.lii))
       IF m.llSame
          IF m.llFirst
\
\* * *
\## Variables - Metuzalem
\| Name  | Type | Default Value |
\|:------------- |:------------- |:------------- |
             m.llFirst=.F.
          ENDIF
          \| \<<m.laEL_Vars(m.lii)>> | <<m.laEL_Types(m.lii)>> | `<<IIF(m.lcPom="O", "Object", IIF(m.lcPom="C" AND EMPTY(m.laEL_DValues(m.lii)), ' ', m.laEL_DValues(m.lii)))>>` |
       ENDIF
    ENDIF
NEXT


* Reset values
m.lcErr=ON("ERROR")
ON ERROR m.llErr=.T.
FOR m.lii=1 TO ALEN(m.laEL_Vars)
    IF !INLIST(m.laEL_Types(m.lii), "U", "R")
       STORE m.laEL_DValues(m.lii) TO (m.laEL_Vars(m.lii))
    ENDIF
NEXT
IF EMPTY(m.lcErr)
   ON ERROR
ELSE
   ON ERROR &lcErr.
ENDIF

SET TEXTMERGE OFF
=FCLOSE( m.liEL_hFile)

